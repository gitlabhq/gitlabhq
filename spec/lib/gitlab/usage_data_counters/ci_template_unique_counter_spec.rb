# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::CiTemplateUniqueCounter do
  describe '.track_unique_project_event' do
    using RSpec::Parameterized::TableSyntax

    let(:project_id) { 1 }

    shared_examples 'tracks template' do
      it "has an event defined for template" do
        expect do
          described_class.track_unique_project_event(
            project_id: project_id,
            template: template_path,
            config_source: config_source
          )
        end.not_to raise_error
      end

      it "tracks template" do
        expanded_template_name = described_class.expand_template_name(template_path)
        expected_template_event_name = described_class.ci_template_event_name(expanded_template_name, config_source)
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to(receive(:track_event)).with(expected_template_event_name, values: project_id)

        described_class.track_unique_project_event(project_id: project_id, template: template_path, config_source: config_source)
      end
    end

    context 'with explicit includes' do
      let(:config_source) { :repository_source }

      (described_class.ci_templates - ['Verify/Browser-Performance.latest.gitlab-ci.yml', 'Verify/Browser-Performance.gitlab-ci.yml']).each do |template|
        context "for #{template}" do
          let(:template_path) { template }

          include_examples 'tracks template'
        end
      end
    end

    context 'with implicit includes' do
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
        described_class.track_unique_project_event(project_id: 1, template: 'Dependency-Scanning.gitlab-ci.yml', config_source: :repository_source)
      end.not_to raise_error
    end
  end
end
