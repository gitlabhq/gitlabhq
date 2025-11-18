# frozen_string_literal: true

module Ci
  module JobFactoryHelpers
    # Temp job definitions should not change in normal operation;
    # only use this method as a helper in factory definitions.
    def self.mutate_temp_job_definition(job, **new_config)
      # Deep merge is required because job config changes are meant to be cumulative within factories
      updated_config = (job.temp_job_definition&.config || {}).deep_merge(new_config)

      new_temp_job_definition = ::Ci::JobDefinition.fabricate(
        config: updated_config,
        project_id: job.pipeline.project.id,
        partition_id: job.pipeline.partition_id
      )

      new_temp_job_definition.validate
      config_errors = new_temp_job_definition.errors[:config]
      raise ActiveRecord::RecordInvalid, new_temp_job_definition if config_errors.any?

      job.temp_job_definition = new_temp_job_definition
    end
  end
end
