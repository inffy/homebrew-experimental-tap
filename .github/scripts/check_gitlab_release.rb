#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "optparse"
require "uri"

# Checks GitLab releases for updates to Homebrew formulas
class GitLabReleaseChecker
  attr_reader :project_path, :formula_name, :gitlab_token, :manual_version

  def initialize(project_path: "asus-linux/asusctl", formula_name: "asusctl", manual_version: nil)
    @project_path = project_path
    @formula_name = formula_name
    @gitlab_token = ENV.fetch("GITLAB_TOKEN", nil)
    @manual_version = manual_version
  end

  def fetch_latest_release
    encoded_path = ERB::Util.url_encode(@project_path)
    url = URI("https://gitlab.com/api/v4/projects/#{encoded_path}/releases/permalink/latest")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Get.new(url)
    request["PRIVATE-TOKEN"] = @gitlab_token if @gitlab_token

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      normalize_version(data["tag_name"] || "")
    else
      warn "Error fetching GitLab release: #{response.code} #{response.message}"
      nil
    end
  rescue StandardError => e
    warn "Error fetching GitLab release: #{e.message}"
    nil
  end

  def normalize_version(version)
    version.sub(/^v/, "")
  end

  def get_formula_version(formula_path = nil)
    formula_path ||= "Formula/#{@formula_name}.rb"

    unless File.exist?(formula_path)
      warn "Formula not found: #{formula_path}"
      return nil
    end

    content = File.read(formula_path, encoding: "utf-8")

    patterns = [
      /tag:\s+"v?([^"]+)"/,
      %r{url.*/archive/v?([^/]+)/asusctl-},
      /version\s+"([^"]+)"/
    ]

    patterns.each do |pattern|
      match = content.match(pattern)
      return normalize_version(match[1]) if match
    end

    nil
  end

  def compare_versions(gitlab_version, formula_version)
    needs_update = gitlab_version != formula_version

    {
      needs_update: needs_update,
      latest_version: gitlab_version,
      current_version: formula_version,
      new_version: needs_update ? gitlab_version : ""
    }
  end

  def set_github_output(data)
    return unless ENV["GITHUB_OUTPUT"]

    File.open(ENV["GITHUB_OUTPUT"], "a") do |file|
      data.each do |key, value|
        value = value.to_s.downcase if [true, false].include?(value)
        file.puts "#{key}=#{value}"
        file.puts "#{@formula_name}_#{key}=#{value}"
      end
    end
  end

  def write_github_summary(data)
    return unless ENV["GITHUB_STEP_SUMMARY"]

    status = data[:needs_update] ? "Update needed" : "Up-to-date"
    action = data[:needs_update] ? "Formula will be updated automatically" : "No action required"

    summary = <<~MARKDOWN
      # GitLab Release Check Results

      ## Formula: #{@formula_name}

      | Property | Value |
      |----------|-------|
      | Current Formula Version | #{data[:current_version]} |
      | Latest GitLab Release | #{data[:latest_version]} |
      | Status | #{status} |
      | Action | #{action} |

      ### Details
      - **Project**: #{@project_path}
      - **Checked at**: GitLab API latest release endpoint
    MARKDOWN

    File.open(ENV["GITHUB_STEP_SUMMARY"], "a") do |file|
      file.write(summary)
    end
  end

  def run
    gitlab_version = if @manual_version
      puts "Using manually specified version: #{@manual_version}"
      normalize_version(@manual_version)
    else
      puts "Checking GitLab for latest release..."
      version = fetch_latest_release

      unless version
        warn "Failed to fetch GitLab release"
        return 1
      end

      version
    end

    puts "Target version: #{gitlab_version}"

    formula_version = get_formula_version
    if formula_version.nil?
      puts "Could not determine formula version, assuming update needed"
      formula_version = "unknown"
    else
      puts "Current formula version: #{formula_version}"
    end

    result = compare_versions(gitlab_version, formula_version)
    set_github_output(result)
    write_github_summary(result)

    if result[:needs_update]
      puts "New version available: #{gitlab_version} → Update needed!"
      puts "New #{@formula_name} version #{gitlab_version} is available"
    else
      puts "Formula is up-to-date at version #{gitlab_version}"
    end

    0
  end
end

def main
  options = {
    formula: "asusctl",
    project: "asus-linux/asusctl",
    version: nil
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: check_gitlab_release.rb [options]"

    opts.on("--formula FORMULA", "Formula name (default: asusctl)") do |v|
      options[:formula] = v
    end

    opts.on("--project PROJECT", "GitLab project path (default: asus-linux/asusctl)") do |v|
      options[:project] = v
    end

    opts.on("--version VERSION", "Manually specify version to check against (skips GitLab API call)") do |v|
      options[:version] = v
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  checker = GitLabReleaseChecker.new(
    project_path: options[:project],
    formula_name: options[:formula],
    manual_version: options[:version]
  )

  exit(checker.run)
end

main if __FILE__ == $PROGRAM_NAME
