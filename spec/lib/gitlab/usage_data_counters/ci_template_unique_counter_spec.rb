# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::CiTemplateUniqueCounter do
  describe '.track_unique_project_event' do
    using RSpec::Parameterized::TableSyntax
    include SnowplowHelpers

    let(:project) { build(:project) }
    let(:user) { build(:user) }

    shared_examples 'tracks template' do
      let(:subject) { described_class.track_unique_project_event(project: project, template: template_path, config_source: config_source, user: user) }
      let(:template_name) do
        expanded_template_name = described_class.expand_template_name(template_path)
        described_class.ci_template_event_name(expanded_template_name, config_source)
      end

      it "has an event defined for template" do
        expect do
          subject
        end.not_to raise_error
      end

      it "tracks template" do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to(receive(:track_event)).with(template_name, values: project.id)

        subject
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:category) { described_class.to_s }
        let(:action) { 'ci_templates_unique' }
        let(:namespace) { project.namespace }
        let(:label) { 'redis_hll_counters.ci_templates.ci_templates_total_unique_counts_monthly' }
        let(:context) { [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: template_name).to_context] }
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

    context 'with implicit includes', :snowplow do
      let(:config_source) { :auto_devops_source }

      described_class.all_included_templates('Auto-DevOps.gitlab-ci.yml').each do |template_name|
        context "for #{template_name}" do
          let(:template_path) { Gitlab::Template::GitlabCiYmlTemplate.find(template_name.delete_suffix('.gitlab-ci.yml')).full_name }

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
