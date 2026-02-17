# frozen_string_literal: true

module Ci
  module PipelineVariableHelpers
    # This method destroys any existing pipeline variables before rebuilding them
    def build_or_replace_pipeline_variables(pipeline, variables_attributes)
      variables_attributes = Array.wrap(variables_attributes).map(&:symbolize_keys)

      pipeline.association(:variables).reader.each(&:destroy!)
      pipeline.association(:variables).reset
      pipeline.pipeline_artifacts_pipeline_variables&.destroy!
      pipeline.association(:pipeline_artifacts_pipeline_variables).reset
      pipeline.clear_memoization(:variables)

      return if variables_attributes.empty?

      # Always write to DB (stop_writing_to_ci_pipeline_variables FF does not exist yet).
      # When the FF is introduced in a future MR, this block will be wrapped with
      # `if Feature.disabled?(:stop_writing_to_ci_pipeline_variables, pipeline.project)`
      variables_attributes.each do |var_attrs|
        pipeline.association(:variables).target <<
          FactoryBot.build(:ci_pipeline_variable, pipeline: pipeline, **var_attrs)
      end

      Gitlab::Ci::Pipeline::Build::PipelineVariablesArtifactBuilder.new(pipeline, variables_attributes).run
    end

    def create_or_replace_pipeline_variables(pipeline, variables_attributes)
      build_or_replace_pipeline_variables(pipeline, variables_attributes)

      # Always save to DB (stop_writing_to_ci_pipeline_variables FF does not exist yet).
      pipeline.association(:variables).target.each(&:save!)
      pipeline.association(:variables).reset

      pipeline.pipeline_artifacts_pipeline_variables&.save!
    end
  end
end
