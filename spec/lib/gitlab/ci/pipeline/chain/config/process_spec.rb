# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Config::Process, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:pipeline) { build(:ci_pipeline, project: project, ref: 'master') }
  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master',
      save_incompleted: true
    )
  end

  let(:step) { described_class.new(pipeline, command) }

  before do
    stub_ci_pipeline_yaml_file(ci_yaml)
    Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command).perform!
  end

  describe '#perform!' do
    subject(:perform) { step.perform! }

    context 'when config is valid' do
      let(:ci_yaml) { YAML.dump(test_job: { stage: 'test', script: 'echo test' }) }

      it 'sets yaml_processor_result on command', :aggregate_failures do
        perform

        expect(command.yaml_processor_result).to be_present
        expect(command.yaml_processor_result).to be_valid
        expect(step.break?).to be false
      end
    end

    context 'when all includes are filtered out leaving no visible jobs' do
      let(:ci_yaml) do
        <<~YAML
          include:
            - local: .filtered.yml
              rules:
                - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        YAML
      end

      it 'reports filtered_by_rules instead of config_error', :aggregate_failures do
        perform

        expect(pipeline.failure_reason).to eq('filtered_by_rules')
        expect(pipeline.errors.full_messages).to include(a_string_including('would have been empty'))
      end

      context 'when the ci_skip_pipelines_with_fully_filtered_includes flag is disabled' do
        before do
          stub_feature_flags(ci_skip_pipelines_with_fully_filtered_includes: false)
        end

        it 'falls back to config_error', :aggregate_failures do
          perform

          expect(pipeline.failure_reason).to eq('config_error')
          expect(pipeline.errors.full_messages).to include(a_string_including('at least one visible job'))
        end
      end
    end

    context 'when config genuinely has no jobs and no includes' do
      let(:ci_yaml) { YAML.dump(stages: ['test']) }

      it 'reports config_error', :aggregate_failures do
        perform

        expect(pipeline.failure_reason).to eq('config_error')
        expect(pipeline.errors.full_messages).to include(a_string_including('at least one visible job'))
      end
    end

    context 'when config has a syntax error' do
      let(:ci_yaml) { 'invalid: yaml: content: [' }

      it 'reports config_error', :aggregate_failures do
        perform

        expect(step.break?).to be true
        expect(pipeline.failure_reason).to eq('config_error')
      end
    end
  end
end
