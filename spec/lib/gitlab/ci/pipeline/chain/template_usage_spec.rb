# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::TemplateUsage do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { create(:ci_pipeline, project: project) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    it 'tracks the included templates' do
      expect(command).to(
        receive(:yaml_processor_result)
          .and_return(
            double(included_templates: %w[Template-1 Template-2])
          )
      )

      %w[Template-1 Template-2].each do |expected_template|
        expect(Gitlab::UsageDataCounters::CiTemplateUniqueCounter).to(
          receive(:track_unique_project_event)
            .with(project: project, template: expected_template, config_source: pipeline.config_source, user: user)
        )
      end

      perform
    end
  end
end
