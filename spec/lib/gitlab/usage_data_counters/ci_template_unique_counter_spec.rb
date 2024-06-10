# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::CiTemplateUniqueCounter, feature_category: :pipeline_composition do
  describe '.track_unique_project_event' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    shared_examples 'tracks template' do
      let(:subject) { described_class.track_unique_project_event(project: project, template: template_path, config_source: config_source, user: user) }
      let(:template_name) do
        expanded_template_name = described_class.expand_template_name(template_path)
        described_class.ci_template_event_name(expanded_template_name, config_source)
      end

      it 'has an event defined for template' do
        expect do
          subject
        end.not_to raise_error
      end

      it 'tracks internal events and increments usage metrics', :clean_gitlab_redis_shared_state do
        expect { subject }
          .to trigger_internal_events('ci_template_included')
            .with(project: project, user: user, category: 'InternalEventTracking')
          .and increment_usage_metrics(
            'redis_hll_counters.ci_templates.count_distinct_project_id_from_ci_template_included_7d',
            'redis_hll_counters.ci_templates.count_distinct_project_id_from_ci_template_included_28d',
            "redis_hll_counters.ci_templates.#{template_name}_weekly",
            "redis_hll_counters.ci_templates.#{template_name}_monthly"
          )
      end
    end

    context 'with explicit includes', :snowplow do
      let(:config_source) { :repository_source }

      (described_class.ci_templates - ['Verify/Browser-Performance.latest.gitlab-ci.yml', 'Verify/Browser-Performance.gitlab-ci.yml']).each do |template|
        context "for #{template}" do
          let(:template_path) { template }

          include_examples 'tracks template'
        end
      end
    end

    it 'expands short template names' do
      expect do
        described_class.track_unique_project_event(project: project, template: 'Dependency-Scanning.gitlab-ci.yml', config_source: :repository_source, user: user)
      end.not_to raise_error
    end
  end
end
