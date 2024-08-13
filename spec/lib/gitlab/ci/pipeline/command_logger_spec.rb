# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::CommandLogger, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#commit' do
    let(:logger) { described_class.new }

    shared_examples 'logs pipeline chain command to application.json' do
      it 'logs to application.json' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(expected_data))
          .and_call_original

        commit = logger.commit(pipeline: pipeline, command: command)

        expect(commit).to be_truthy
      end

      context 'when feature flag disabled' do
        before do
          stub_feature_flags(ci_pipeline_command_logger_commit: false)
        end

        it 'does not log' do
          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          commit = logger.commit(pipeline: pipeline, command: command)

          expect(commit).to be_falsey
        end
      end
    end

    context 'for a minimal command' do
      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new
      end

      let(:expected_data) do
        {
          'correlation_id' => a_kind_of(String),
          'pipeline_id' => pipeline.id,
          'pipeline_persisted' => true
        }
      end

      include_examples 'logs pipeline chain command to application.json'
    end

    context 'for a command with project' do
      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(project: project)
      end

      let(:expected_data) do
        {
          'correlation_id' => a_kind_of(String),
          'pipeline_command.project_id' => project.id,
          'pipeline_id' => pipeline.id,
          'pipeline_persisted' => true
        }
      end

      include_examples 'logs pipeline chain command to application.json'
    end

    context 'for a command with current_user' do
      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(
          project: project,
          current_user: project.owner
        )
      end

      let(:expected_data) do
        {
          'correlation_id' => a_kind_of(String),
          'pipeline_command.project_id' => project.id,
          'pipeline_command.current_user_id' => project.owner.id,
          'pipeline_id' => pipeline.id,
          'pipeline_persisted' => true
        }
      end

      include_examples 'logs pipeline chain command to application.json'
    end

    context 'for a command with merge_request' do
      let_it_be(:merge_request) { create(:merge_request, source_project: project) }

      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(
          project: project,
          merge_request: merge_request
        )
      end

      let(:expected_data) do
        {
          'correlation_id' => a_kind_of(String),
          'pipeline_command.project_id' => project.id,
          'pipeline_command.merge_request_id' => merge_request.id,
          'pipeline_id' => pipeline.id,
          'pipeline_persisted' => true
        }
      end

      include_examples 'logs pipeline chain command to application.json'
    end
  end
end
