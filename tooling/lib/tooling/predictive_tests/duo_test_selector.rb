#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'
require 'optparse'
require 'fileutils'
require 'benchmark'
require 'logger'

module Tooling
  module PredictiveTests
    # rubocop:disable Gitlab/Json -- not rails
    class DuoTestSelector
      CONFIDENCE_THRESHOLD = 0.8
      PROMPT_FILE = 'tooling/lib/tooling/predictive_tests/duo_test_selection_prompt.txt'
      DUO_OUTPUT_FILE = 'duo_feature_specs.json'

      # Safety limits
      MAX_DIFF_LINES = 5000
      MAX_CHANGED_FILES = 50

      def initialize(git_diff: nil, changed_files: nil, logger: nil)
        @git_diff = git_diff
        @changed_files = changed_files
        @logger = logger || Logger.new($stdout, progname: "duo test selector")
      end

      # Selects system specs to run based on git diff analysis
      # Returns hash with confidence, specs array, and metadata
      def select_tests
        diff = @git_diff || get_git_diff

        return fallback_result('No git diff', 0) if !diff || diff.empty?

        # Validate diff size constraints
        safety_check_result = check_safety_limits(diff)
        return safety_check_result if safety_check_result

        # Analyze with Duo
        analyze_with_duo(diff)
      end

      private

      def check_safety_limits(diff)
        changed_files = @changed_files || extract_changed_files(diff)
        diff_lines = diff.lines.count

        if changed_files.length > MAX_CHANGED_FILES
          @logger.warn "⚠️  Large change: #{changed_files.length} files (limit: #{MAX_CHANGED_FILES})"
          @logger.warn "     Skipping Duo analysis to save costs"
          return low_confidence_result(
            "Large change (#{changed_files.length} files exceeds limit). Skipping Duo to save costs.",
            changed_files
          )
        end

        if diff_lines > MAX_DIFF_LINES
          @logger.warn "⚠️  Very large diff: #{diff_lines} lines (limit: #{MAX_DIFF_LINES})"
          @logger.warn "     Skipping Duo analysis to save costs"
          return low_confidence_result(
            "Very large diff (#{diff_lines} lines exceeds limit). Skipping Duo to save costs.",
            changed_files
          )
        end

        nil
      end

      def analyze_with_duo(diff)
        changed_files = @changed_files || extract_changed_files(diff)
        diff_lines = diff.lines.count

        @logger.debug "📝 Analyzing git diff:"
        @logger.debug "   Lines: #{diff_lines}"
        @logger.debug "   Files: #{changed_files.length}"
        @logger.debug "   Within limits ✓"
        changed_files.each { |f| @logger.debug "     - #{f}" }

        prompt = build_prompt(diff)

        response = nil
        elapsed_time = Benchmark.realtime do
          response = call_duo_cli(prompt)
        end

        @logger.debug "⏱️  Duo CLI response time: #{elapsed_time.round(2)}s"

        return fallback_result('Duo CLI failed', elapsed_time) unless response

        result = parse_response(response)
        return fallback_result('Failed to parse Duo response', elapsed_time) unless result

        specs = expand_to_specs(result[:directories] || [], result[:individual_files] || [])

        {
          confidence: result[:confidence],
          specs: specs,
          directories: result[:directories] || [],
          individual_files: result[:individual_files] || [],
          reasoning: result[:reasoning],
          response_time: elapsed_time.round(2),
          changed_files: changed_files
        }
      end

      # rubocop:disable Gitlab/NoCodeCoverageComment -- only called when no diff is injected, untestable with frozen $?
      # :nocov:
      # Used as a fallback for local development when running outside of CI.
      def get_git_diff
        diff = `git diff HEAD~1 HEAD 2>/dev/null`.strip
        return diff if $?.success? && !diff.empty?

        diff = `git diff --cached 2>/dev/null`.strip
        return diff if $?.success? && !diff.empty?

        diff = `git diff 2>/dev/null`.strip
        return diff if $?.success? && !diff.empty?

        nil
      end
      # :nocov:
      # rubocop:enable Gitlab/NoCodeCoverageComment

      def extract_changed_files(diff)
        diff.scan(%r{^\+\+\+ b/(.+)$}).flatten.uniq
      end

      def build_prompt(diff)
        base_prompt = File.read(PROMPT_FILE)

        @logger.debug "📏 Diff size: #{diff.lines.count} lines (#{diff.length} chars)"

        <<~PROMPT
          #{base_prompt}

          GIT DIFF:
          ```diff
          #{diff}
          ```

          Analyze this diff and return your JSON response with directories and individual files.
        PROMPT
      end

      def call_duo_cli(prompt)
        @logger.debug "🤖 Calling Duo CLI..."

        File.write('tmp/.duo_last_prompt.txt', prompt)
        @logger.debug "💾 Prompt saved to tmp/.duo_last_prompt.txt"

        # Remove any existing output file so we can detect if Duo wrote a new one
        FileUtils.rm_f(DUO_OUTPUT_FILE)

        cmd = ['duo', 'run', '--goal', prompt, '--log-level', 'info']

        gitlab_token = ENV['DUO_TEST_SELECTION_TOKEN']

        if gitlab_token
          @logger.debug "🔑 Using DUO_TEST_SELECTION_TOKEN for Duo authentication"
        else
          @logger.warn "⚠️  DUO_TEST_SELECTION_TOKEN not set - will try default Duo CLI auth"
        end

        combined_output, status = Open3.capture2e({ 'GITLAB_TOKEN' => gitlab_token }, *cmd)

        File.write('tmp/.duo_last_output.txt', combined_output)

        @logger.debug "📤 Duo CLI exit status: #{status.exitstatus}"

        unless status.success?
          @logger.warn "❌ Duo CLI exited with status: #{status.exitstatus}"
          return
        end

        if combined_output.empty?
          @logger.warn "⚠️  Duo CLI returned no output"
          return
        end

        @logger.debug "✅ Duo CLI completed"
        combined_output
      end

      def parse_response(_response)
        @logger.debug "📊 Parsing Duo response from #{DUO_OUTPUT_FILE}..."

        unless File.exist?(DUO_OUTPUT_FILE)
          @logger.warn "⚠️  #{DUO_OUTPUT_FILE} not found - Duo may not have saved results"
          return
        end

        json_str = File.read(DUO_OUTPUT_FILE)

        if json_str.strip.empty?
          @logger.warn "⚠️  #{DUO_OUTPUT_FILE} is empty"
          return
        end

        @logger.debug "📝 Read #{json_str.length} chars from #{DUO_OUTPUT_FILE}"

        result = JSON.parse(json_str, symbolize_names: true)
        validate_response(result)
      rescue JSON::ParserError => e
        @logger.warn "❌ Failed to parse #{DUO_OUTPUT_FILE}: #{e.message}"
        @logger.warn "    Content: #{json_str.to_s.slice(0, 200)}"
        nil
      end

      def validate_response(result)
        directories = result[:directories] || []
        individual_files = result[:individual_files] || []

        unless directories.is_a?(Array) && individual_files.is_a?(Array)
          @logger.warn "❌ Response missing valid directories or individual_files arrays"
          return
        end

        # Move any .rb files mistakenly placed in directories array to individual_files
        rb_files_in_dirs = directories.select { |d| d.end_with?('.rb') }
        if rb_files_in_dirs.any?
          @logger.warn "⚠️  Moving #{rb_files_in_dirs.length} .rb files from directories array to files:"
          rb_files_in_dirs.each { |f| @logger.warn "    - #{f}" }

          result[:directories] = directories.reject { |d| d.end_with?('.rb') }
          result[:individual_files] = (individual_files + rb_files_in_dirs).uniq
        end

        @logger.debug "📋 Duo identified: #{result[:directories].length} directories"
        @logger.debug "📋 Duo identified: #{result[:individual_files].length} individual files"

        result
      end

      def expand_to_specs(directories, individual_files)
        specs = []

        directories.each do |dir|
          dir = dir.chomp('/')
          unless Dir.exist?(dir)
            @logger.warn "⚠️  Duo predicted non-existent directory: #{dir} — possible hallucination"
            next
          end

          found = Dir.glob("#{dir}/**/*_spec.rb")
          @logger.debug "📂 #{dir}: found #{found.length} specs (recursive)"
          specs.concat(found)
        end

        individual_files.each do |file|
          if File.exist?(file)
            @logger.debug "📄 Individual: #{file}"
            specs << file
          else
            @logger.warn "⚠️  Duo predicted non-existent file: #{file} — possible hallucination"
          end
        end

        specs.uniq.select do |spec|
          spec.start_with?('spec/features/', 'ee/spec/features/') &&
            spec.end_with?('_spec.rb')
        end
      end

      def fallback_result(reason, elapsed_time)
        @logger.debug "⚠️  #{reason}"
        {
          confidence: 0.0,
          specs: [],
          directories: [],
          individual_files: [],
          reasoning: reason,
          response_time: elapsed_time.round(2),
          changed_files: []
        }
      end

      def low_confidence_result(reason, changed_files)
        {
          confidence: 0.0,
          specs: [],
          directories: [],
          individual_files: [],
          reasoning: reason,
          response_time: 0,
          changed_files: changed_files
        }
      end
    end

    # rubocop:disable Gitlab/NoCodeCoverageComment -- CLI entrypoint, only executed when run directly
    # :nocov:
    if __FILE__ == $PROGRAM_NAME
      OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
        opts.on('-h', '--help') do
          puts opts
          exit
        end
      end.parse!

      cli_logger = Logger.new($stdout, progname: "duo test selector")
      cli_logger.level = Logger::INFO

      begin
        selector = DuoTestSelector.new(changed_files: nil, logger: cli_logger)
        result = selector.select_tests

        puts "\n#{'=' * 80}"
        puts "Duo Feature Spec Selector Results"
        puts "#{'=' * 80}\n"
        puts "⏱️  Response time: #{result[:response_time]}s"
        puts "🎯 Confidence: #{(result[:confidence] * 100).round(1)}%"
        puts "📁 Changed files: #{result[:changed_files]&.length || 0}"
        puts "📂 Directories identified: #{result[:directories]&.length || 0}"
        puts "📄 Individual files identified: #{result[:individual_files]&.length || 0}\n\n"

        if result[:specs].empty?
          if result[:confidence] >= DuoTestSelector::CONFIDENCE_THRESHOLD
            puts "✅ HIGH CONFIDENCE - No system specs needed"
            puts ""
            puts "📋 Reason:"
            puts "   #{result[:reasoning]}"
            puts ""
            puts "💡 Duo is confident that no system specs are affected by this change."
            puts ""
          else
            puts "⚠️  LOW CONFIDENCE - Run all system specs"
            puts ""
            puts "Reason:\n  #{result[:reasoning]}"
            puts ""
            puts "Triggers:"
            puts "  - Confidence < #{(DuoTestSelector::CONFIDENCE_THRESHOLD * 100).round}%"
            puts "  - Change exceeds #{DuoTestSelector::MAX_CHANGED_FILES} files"
            puts "  - Diff exceeds #{DuoTestSelector::MAX_DIFF_LINES} lines"
            puts "  - Duo analysis failed"
          end
        elsif result[:confidence] < DuoTestSelector::CONFIDENCE_THRESHOLD
          puts "⚠️  LOW CONFIDENCE (#{(result[:confidence] * 100).round(1)}%) - Run all system specs"
          puts ""
          puts "Reason:\n  #{result[:reasoning]}"
          puts ""
          puts "Note: Duo found #{result[:specs].length} specs but confidence is below threshold."
          puts "Duo recommends to run all system tests for safety."
        else
          ce = result[:specs].count { |s| s.start_with?('spec/features/') }
          ee = result[:specs].count { |s| s.start_with?('ee/spec/features/') }

          puts "✅ Recommended: #{result[:specs].length} feature spec files)"
          puts "  - CE: #{ce}, EE: #{ee}\n\n"

          if result[:directories]&.any?
            puts "Directories searched:"
            result[:directories].each { |d| puts "  - #{d}" }
            puts ""
          end

          if result[:individual_files]&.any?
            puts "Individual files included:"
            result[:individual_files].each { |f| puts "  - #{f}" }
            puts ""
          end

          puts "Reasoning:\n  #{result[:reasoning]}\n\n"
          puts "Specs:\n"
          result[:specs].sort.each { |s| puts "  - #{s}" }
          puts "\nCommand:\n  bundle exec rspec #{result[:specs].join(' ')}\n"
        end

        puts('=' * 80)
      rescue StandardError => e
        warn "❌ Error: #{e.message}"
        warn e.backtrace.join("\n")
        exit 1
      end
    end
    # :nocov:
    # rubocop:enable Gitlab/NoCodeCoverageComment

    # rubocop:enable Gitlab/Json
  end
end
