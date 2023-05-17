# frozen_string_literal: true

module Ci
  module SourcePipelineHelpers
    def create_source_pipeline(upstream, downstream)
      create(
        :ci_sources_pipeline,
        source_job: create(:ci_build, pipeline: upstream),
        source_project: upstream.project,
        pipeline: downstream,
        project: downstream.project
      )
    end
  end
end
