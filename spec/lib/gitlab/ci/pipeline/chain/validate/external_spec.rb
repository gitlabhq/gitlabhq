# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::External do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
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
  let(:dot_com) { true }
  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user, yaml_processor_result: yaml_processor_result, save_incompleted: save_incompleted
    )
  end

  describe '#perform!' do
    subject(:perform!) { step.perform! }

    let(:validation_service_url) { 'https://validation-service.external/' }

    before do
      stub_env('EXTERNAL_VALIDATION_SERVICE_URL', validation_service_url)
      allow(Gitlab).to receive(:com?).and_return(dot_com)
    end

    it 'respects the defined payload schema' do
      expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
        expect(params[:body]).to match_schema('/external_validation')
        expect(params[:timeout]).to eq(described_class::DEFAULT_VALIDATION_REQUEST_TIMEOUT)
      end

      perform!
    end

    context 'with EXTERNAL_VALIDATION_SERVICE_TIMEOUT defined' do
      before do
        stub_env('EXTERNAL_VALIDATION_SERVICE_TIMEOUT', validation_service_timeout)
      end

      context 'with valid value' do
        let(:validation_service_timeout) { '1' }

        it 'uses defined timeout' do
          expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
            expect(params[:timeout]).to eq(1)
          end

          perform!
        end
      end

      context 'with invalid value' do
        let(:validation_service_timeout) { '??' }

        it 'uses default timeout' do
          expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
            expect(params[:timeout]).to eq(described_class::DEFAULT_VALIDATION_REQUEST_TIMEOUT)
          end

          perform!
        end
      end
    end

    shared_examples 'successful external authorization' do
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

    context 'when validation returns 200 OK' do
      before do
        stub_request(:post, validation_service_url).to_return(status: 200, body: "{}")
      end

      it_behaves_like 'successful external authorization'
    end

    context 'when validation returns 404 Not Found' do
      before do
        stub_request(:post, validation_service_url).to_return(status: 404, body: "{}")
      end

      it_behaves_like 'successful external authorization'
    end

    context 'when validation returns 500 Internal Server Error' do
      before do
        stub_request(:post, validation_service_url).to_return(status: 500, body: "{}")
      end

      it_behaves_like 'successful external authorization'
    end

    context 'when validation raises exceptions' do
      before do
        stub_request(:post, validation_service_url).to_raise(Net::OpenTimeout)
      end

      it_behaves_like 'successful external authorization'

      it 'logs exceptions' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(Net::OpenTimeout), { project_id: project.id })

        perform!
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(ci_external_validation_service: false)
        stub_request(:post, validation_service_url)
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

      it 'does not make requests' do
        perform!

        expect(WebMock).not_to have_requested(:post, validation_service_url)
      end
    end

    context 'when not on .com' do
      let(:dot_com) { false }

      before do
        stub_feature_flags(ci_external_validation_service: false)
        stub_request(:post, validation_service_url).to_return(status: 404, body: "{}")
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
    end

    context 'when validation returns 406 Not Acceptable' do
      before do
        stub_request(:post, validation_service_url).to_return(status: 406, body: "{}")
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
end
