# frozen_string_literal: true

require 'yaml'
require_relative 'graph'

module Tooling
  module DependencyGraph
    # Generates a child pipeline that triggers the pipelines of the in-repo gems affected
    # by the changed files: the changed gems and the gems that depend on them, directly or
    # transitively. Gems are the directories in `gems/` and `vendor/gems/` with a `.gitlab-ci.yml`.
    class GenerateGemsPipeline
      NO_GEMS_JOB_NAME = 'no-gems-to-test'

      # @param changed_files_path [String, nil] file with the changed files separated by whitespace.
      #   When it is not given, missing or empty, all gems are tested.
      def initialize(output_path:, parent_pipeline_id:, changed_files_path: nil, root: Dir.pwd)
        @output_path = output_path
        @parent_pipeline_id = parent_pipeline_id
        @changed_files_path = changed_files_path
        @root = root
      end

      def generate!
        jobs = gem_dirs.to_h { |dir| ["gems #{File.basename(dir)}", trigger_job(dir)] }
        jobs = { NO_GEMS_JOB_NAME => no_gems_job } if jobs.empty?

        File.write(output_path, jobs.to_yaml)
      end

      private

      attr_reader :output_path, :parent_pipeline_id, :changed_files_path, :root

      def gem_dirs
        graph = Graph.new(root: root)
        dirs = test_all? ? graph.to_h.keys : graph.affected_by(changed_files)

        dirs.select do |dir|
          dir != Graph::MONOLITH && File.exist?(File.join(root, dir, '.gitlab-ci.yml'))
        end
      end

      def test_all?
        changed_files_path.nil? || !File.exist?(changed_files_path) || File.zero?(changed_files_path)
      end

      def changed_files
        File.read(changed_files_path).split
      end

      def trigger_job(dir)
        {
          'trigger' => { 'include' => "#{dir}/.gitlab-ci.yml", 'strategy' => 'depend' },
          'inherit' => { 'variables' => false },
          'variables' => {
            'FF_NETWORK_PER_BUILD' => 'true',
            'PARENT_PIPELINE_ID' => parent_pipeline_id,
            'CI_FETCH_REPO_GIT_STRATEGY' => 'none'
          }
        }
      end

      # A child pipeline needs at least one job. This job is rare: it runs only when the changes
      # under gems/ or vendor/gems/ are not in a gem with a .gitlab-ci.yml, for example
      # gems/README.md or a gem without a CI pipeline, like gems/error_tracking_open_api.
      def no_gems_job
        {
          'image' => "#{ENV['GITLAB_DEPENDENCY_PROXY_ADDRESS']}alpine:latest",
          'tags' => ['gitlab-org'],
          'variables' => { 'GIT_STRATEGY' => 'none' },
          'script' => ['echo "No in-repo gems are affected by the changes."']
        }
      end
    end
  end
end
