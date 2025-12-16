# frozen_string_literal: true

module Ci
  module JobHelpers
    def stub_ci_job_definition(job, **new_config)
      new_config.symbolize_keys!
      unknown_keys = new_config.keys - Ci::JobDefinition::CONFIG_ATTRIBUTES

      if unknown_keys.any?
        raise ArgumentError,
          "You can only stub valid job definition config attributes. Invalid key(s): #{unknown_keys.join(', ')}. " \
            "Allowed: #{Ci::JobDefinition::CONFIG_ATTRIBUTES.join(', ')}"
      end

      # We use regular merge (not deep_merge) to completely overwrite existing attributes
      updated_config = (job.job_definition&.config || job.temp_job_definition&.config || {}).merge(new_config)

      new_job_definition = ::Ci::JobDefinition.fabricate(
        config: updated_config,
        project_id: job.pipeline.project.id,
        partition_id: job.pipeline.partition_id
      )

      new_job_definition.validate
      config_errors = new_job_definition.errors[:config]
      raise ActiveRecord::RecordInvalid, new_job_definition if config_errors.any?

      allow(job).to receive(:job_definition).and_return(new_job_definition)
    end
  end
end
