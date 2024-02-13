# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::CiTemplateUniqueCounter, feature_category: :pipeline_composition do
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

      it 'has an event defined for template' do
        expect do
          subject
        end.not_to raise_error
      end

      it 'tracks template' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event).with(template_name, values: project.id).once
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event).with('ci_template_included', values: project.id, property_name: :project).once

        subject
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'ci_template_included' }
        let(:namespace) { project.namespace }
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
