# frozen_string_literal: true

module MigrationHelpers
  module PrometheusServiceHelpers
    def service_params_for(project_id, params = {})
      {
        project_id: project_id,
        active: false,
        properties: '{}',
        type: 'PrometheusService',
        template: false,
        push_events: true,
        issues_events: true,
        merge_requests_events: true,
        tag_push_events: true,
        note_events: true,
        category: 'monitoring',
        default: false,
        wiki_page_events: true,
        pipeline_events: true,
        confidential_issues_events: true,
        commit_events: true,
        job_events: true,
        confidential_note_events: true,
        deployment_events: false
      }.merge(params)
    end

    def row_attributes(entity)
      entity.attributes.with_indifferent_access.tap do |hash|
        hash.merge!(hash.slice(:created_at, :updated_at).transform_values { |v| v.to_s(:db) })
      end
    end
  end
end
