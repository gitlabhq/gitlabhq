# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::External do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:pipeline) { build(:ci_empty_pipeline, user: user, project: project) }
  let!(:step) { described_class.new(pipeline, command) }

  let(:ci_yaml) do
    <<-CI_YAML
    stages:
      - first_stage
      - second_stage

    first_stage_job_name:
      stage: first_stage
      image: hello_world
      script:
        - echo 'hello'

    second_stage_job_name:
      stage: second_stage
      services:
        - postgres
      before_script:
        - echo 'first hello'
      script:
        - echo 'second hello'
    CI_YAML
  end

  let(:yaml_processor_result) do
    ::Gitlab::Ci::YamlProcessor.new(
      ci_yaml, {
        project: project,
        sha: pipeline.sha,
        user: user
      }
    ).execute
  end

  let(:save_incompleted) { true }
  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user, yaml_processor_result: yaml_processor_result, save_incompleted: save_incompleted
    )
  end

  describe '#perform!' do
    subject(:perform!) { step.perform! }

    context 'when validation returns true' do
      before do
        allow(step).to receive(:validate_external).and_return(true)
      end

      it 'does not drop the pipeline' do
        perform!

        expect(pipeline.status).not_to eq('failed')
        expect(pipeline.errors).to be_empty
      end

      it 'does not break the chain' do
        perform!

        expect(step.break?).to be false
      end

      it 'logs the authorization' do
        expect(Gitlab::AppLogger).to receive(:info).with(message: 'Pipeline authorized', project_id: project.id, user_id: user.id)

        perform!
      end
    end

    context 'when validation return false' do
      before do
        allow(step).to receive(:validate_external).and_return(false)
      end

      it 'drops the pipeline' do
        perform!

        expect(pipeline.status).to eq('failed')
        expect(pipeline).to be_persisted
        expect(pipeline.errors.to_a).to include('External validation failed')
      end

      it 'breaks the chain' do
        perform!

        expect(step.break?).to be true
      end

      it 'logs the authorization' do
        expect(Gitlab::AppLogger).to receive(:info).with(message: 'Pipeline not authorized', project_id: project.id, user_id: user.id)

        perform!
      end

      context 'when save_incompleted is false' do
        let(:save_incompleted) { false}

        it 'adds errors to the pipeline without dropping it' do
          perform!

          expect(pipeline.status).to eq('pending')
          expect(pipeline).not_to be_persisted
          expect(pipeline.errors.to_a).to include('External validation failed')
        end

        it 'breaks the chain' do
          perform!

          expect(step.break?).to be true
        end

        it 'logs the authorization' do
          expect(Gitlab::AppLogger).to receive(:info).with(message: 'Pipeline not authorized', project_id: project.id, user_id: user.id)

          perform!
        end
      end
    end
  end

  describe '#validation_service_payload' do
    subject(:validation_service_payload) { step.send(:validation_service_payload, pipeline, command.yaml_processor_result.stages_attributes) }

    it 'respects the defined schema' do
      expect(validation_service_payload).to match_schema('/external_validation')
    end

    it 'does not fire sql queries' do
      expect { validation_service_payload }.not_to exceed_query_limit(1)
    end
  end
end
