# frozen_string_literal: true

module Tooling
  module Danger
    module Experiments
      EXPERIMENTS_YML_REGEX = %r{\A(ee/)?config/feature_flags/experiment/}
      CLASS_FILES_DIR = %w[app/experiments/ ee/app/experiments/].freeze

      def class_files_removed?
        (removed_experiments & current_experiments_with_class_files).empty?
      end

      def removed_experiments
        yml_files_paths = helper.deleted_files

        yml_files_paths.select { |path| path =~ EXPERIMENTS_YML_REGEX }.map { |path| File.basename(path).chomp('.yml') }
      end

      private

      def current_experiments_with_class_files
        experiment_names = []

        CLASS_FILES_DIR.each do |directory_path|
          experiment_names += Dir.glob("#{directory_path}*.rb").map do |path|
            File.basename(path).chomp('_experiment.rb')
          end
        end

        experiment_names
      end
    end
  end
end
