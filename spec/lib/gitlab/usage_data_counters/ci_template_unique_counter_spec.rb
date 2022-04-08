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

      it "has an event defined for template" do
        expect do
          subject
        end.not_to raise_error
      end

      it "tracks template" do
        expanded_template_name = described_class.expand_template_name(template_path)
        expected_template_event_name = described_class.ci_template_event_name(expanded_template_name, config_source)
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to(receive(:track_event)).with(expected_template_event_name, values: project.id)

        subject
      end

      context 'Snowplow' do
        it 'event is not tracked if FF is disabled' do
          stub_feature_flags(route_hll_to_snowplow: false)

          subject

          expect_no_snowplow_event
        end

        it 'tracks event' do
          subject

          expect_snowplow_event(
            category: described_class.to_s,
            action: 'ci_templates_unique',
            namespace: project.namespace,
            user: user,
            project: project
          )
        end
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

      [
        ['', ['Auto-DevOps.gitlab-ci.yml']],
        ['Jobs', described_class.ci_templates('lib/gitlab/ci/templates/Jobs')],
        ['Security', described_class.ci_templates('lib/gitlab/ci/templates/Security')]
      ].each do |directory, templates|
        templates.each do |template|
          context "for #{template}" do
            let(:template_path) { File.join(directory, template) }

            include_examples 'tracks template'
          end
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
