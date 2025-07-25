# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'json'
require 'open3'

require_relative 'test_selector'
require_relative 'changed_files'
require_relative 'mapping_fetcher'
require_relative '../find_changes'

module Tooling
  module PredictiveTests
    # rubocop:disable Gitlab/Json, -- non rails
    class Executor
      def initialize(options)
        @with_crystalball_mappings = options[:with_crystalball_mappings]
        @mapping_type = options[:mapping_type] || :described_class
        @with_frontend_fixture_mappings = options[:with_frontend_fixture_mappings]
        @changed_files = options[:changed_files]&.split(' ')
        @changed_files_path = options[:changed_files_path]
        @matching_foss_rspec_test_files_path = options[:matching_foss_rspec_test_files_path]
        @matching_ee_rspec_test_files_path = options[:matching_ee_rspec_test_files_path]
        @matching_js_files_path = options[:matching_js_files_path]
        @ci = options[:ci]
        @debug = options[:debug]

        # unlike backend mappings, this file is reused in other ci jobs so it's location needs to be configurable
        @frontend_fixtures_mapping_path = options[:frontend_fixtures_mapping_path] || File.join(
          Dir.tmpdir, 'frontend_fixtures_mapping.json'
        )
      end

      def execute
        logger.info('Running predictive test selection')
        create_output_files
        return if @ci

        # printf because we want to use the output in shell script without having to handle trailing newline
        printf rspec_spec_list.join(' ')
      end

      private

      def logger
        @logger ||= Logger.new($stdout, progname: 'Predictive Tests').tap do |l|
          l.level = if @debug
                      :debug
                    else
                      # silence logger locally so output can be used in shell scripts
                      @ci ? :info : :error
                    end

          l.formatter = proc do |severity, _datetime, progname, msg|
            # remove datetime to keep more neat cli like output
            "[#{progname}] #{severity}: #{msg}\n"
          end
        end
      end

      def mapping_fetcher
        @mapping_fetcher ||= Tooling::PredictiveTests::MappingFetcher.new(logger: logger)
      end

      def test_mapping_file
        return unless @with_crystalball_mappings

        @test_mapping_file ||= mapping_fetcher.fetch_rspec_mappings(
          File.join(Dir.tmpdir, 'crystalball_mapping.json'),
          type: @mapping_type
        )
      end

      def frontend_fixtures_mapping_file
        return unless @with_frontend_fixture_mappings

        @frontend_fixtures_mapping_file ||= mapping_fetcher.fetch_frontend_fixtures_mappings(
          @frontend_fixtures_mapping_path
        )
      end

      def changed_files
        @changed_files ||= @ci ? mr_diff : git_diff
      end

      def all_changed_files
        @all_changed_files ||= Tooling::PredictiveTests::ChangedFiles.fetch(changes: changed_files)
      end

      def test_selector
        @test_selector ||= begin
          logger.info(
            "Generating predictive test list based on changed files: #{JSON.pretty_generate(all_changed_files)}"
          )

          Tooling::PredictiveTests::TestSelector.new(
            changed_files: all_changed_files,
            rspec_test_mapping_path: test_mapping_file,
            logger: logger
          )
        end
      end

      def rspec_spec_list
        @rspec_spec_list ||= test_selector.rspec_spec_list
      end

      def mr_diff
        logger.debug('Fetching list of changes in gitlab merge request')
        Tooling::FindChanges.new(
          from: :api,
          frontend_fixtures_mapping_pathname: frontend_fixtures_mapping_file
        ).execute
      end

      def git_diff
        logger.debug('Fetching list of changes in local git repository')

        clean = run_git_cmd('status --porcelain').strip.empty?
        return git_local_changes_diff unless clean

        branch = run_git_cmd('rev-parse --abbrev-ref HEAD').strip
        return git_branch_diff unless branch == 'master'

        logger.debug('Running on master branch without local changes, returning empty change list')
        []
      end

      def git_branch_diff
        run_git_cmd('diff --name-only master...HEAD').split("\n")
      end

      def git_local_changes_diff
        run_git_cmd('diff --name-only HEAD').split("\n")
      end

      def create_output_files
        # Used by frontend related pipelines/jobs
        save_output(all_changed_files.join("\n"), @changed_files_path) if valid_file_path?(@changed_files_path)

        # Used by predictive rspec pipelines
        if valid_file_path?(@matching_foss_rspec_test_files_path)
          list = rspec_spec_list.select { |f| f.start_with?("spec/") && File.exist?(f) }
          save_output(list.join(" "), @matching_foss_rspec_test_files_path)
          logger.info("Following foss rspec tests saved: #{JSON.pretty_generate(list)}")
        end

        if valid_file_path?(@matching_ee_rspec_test_files_path)
          list = rspec_spec_list.select { |f| f.start_with?("ee/spec/") && File.exist?(f) }
          save_output(list.join(" "), @matching_ee_rspec_test_files_path)
          logger.info("Following ee rspec tests saved: #{JSON.pretty_generate(list)}")
        end

        return unless valid_file_path?(@matching_js_files_path)

        js_changed_files = Tooling::PredictiveTests::ChangedFiles.fetch(
          changes: changed_files, with_views: true, with_js_files: true
        ).select { |f| Tooling::PredictiveTests::ChangedFiles::JS_FILE_FILTER_REGEX.match?(f) }
        logger.info("Following matching js files saved: #{JSON.pretty_generate(js_changed_files)}")
        save_output(js_changed_files.join("\n"), @matching_js_files_path)
      end

      def save_output(output, file_path)
        logger.debug("Writing #{file_path}")
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, output)
      end

      def valid_file_path?(file_path)
        !(file_path.nil? || file_path.empty?)
      end

      def run_git_cmd(args)
        out, status = Open3.capture2e("git #{args}")
        raise("git command with args '#{args}' failed! Output: #{out}") unless status.success?

        out
      end
    end
    # rubocop:enable Gitlab/Json
  end
end
