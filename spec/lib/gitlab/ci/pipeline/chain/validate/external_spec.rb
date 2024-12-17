# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::External, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, :with_sign_ins) }

  let(:pipeline) { build(:ci_empty_pipeline, user: user, project: project) }
  let!(:step) { described_class.new(pipeline, command) }

  let(:ci_yaml) do
    <<-CI_YAML
    stages:
      - first_stage
      - second_stage

    first_stage_job_name:
      tags:
        - TAG_1
        - TAG_2
      stage: first_stage
      image: hello_world
      script:
        - echo 'hello'

    second_stage_job_name:
      stage: second_stage
      services:
        -
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

    let(:validation_service_url) { 'https://validation-service.external/' }

    before do
      stub_env('EXTERNAL_VALIDATION_SERVICE_URL', validation_service_url)
      allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('correlation-id')
    end

    context 'with configuration values in ApplicationSetting' do
      let(:alternate_validation_service_url) { 'https://alternate-validation-service.external/' }
      let(:validation_service_token) { 'SECURE_TOKEN' }
      let(:shorter_timeout) { described_class::DEFAULT_VALIDATION_REQUEST_TIMEOUT - 1 }

      before do
        stub_env('EXTERNAL_VALIDATION_SERVICE_TOKEN', 'TOKEN_IN_ENV')
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:external_pipeline_validation_service_timeout).and_return(shorter_timeout)
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:external_pipeline_validation_service_token).and_return(validation_service_token)
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:external_pipeline_validation_service_url).and_return(alternate_validation_service_url)
      end

      it 'uses those values rather than env vars or defaults' do
        expect(::Gitlab::HTTP).to receive(:post) do |url, params|
          expect(url).to eq(alternate_validation_service_url)
          expect(params[:timeout]).to eq(shorter_timeout)
          expect(params[:headers]).to include('X-Gitlab-Token' => validation_service_token)
          expect(params[:timeout]).to eq(shorter_timeout)
        end

        perform!
      end
    end

    it 'respects the defined payload schema' do
      expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
        expect(params[:body]).to match_schema('/external_validation')
        expect(params[:timeout]).to eq(described_class::DEFAULT_VALIDATION_REQUEST_TIMEOUT)
        expect(params[:headers]).to eq({ 'X-Gitlab-Correlation-id' => 'correlation-id' })
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

      it 'returns expected payload' do
        expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
          payload = Gitlab::Json.parse(params[:body])

          expect(payload['total_builds_count']).to eq(0)

          builds = payload['builds']
          expect(builds.count).to eq(2)

          expect(builds[0]['name']).to eq('first_stage_job_name')
          expect(builds[0]['services']).to be_nil
          expect(builds[0]['stage']).to eq('first_stage')
          expect(builds[0]['tag_list']).to match_array(%w[TAG_1 TAG_2])
          expect(builds[0]['script']).to match_array(["echo 'hello'"])
          expect(builds[0]['image']).to eq('hello_world')
          expect(builds[1]['name']).to eq('second_stage_job_name')
          expect(builds[1]['services']).to eq(['postgres'])
          expect(builds[1]['stage']).to eq('second_stage')
          expect(builds[1]['image']).to be_nil
          expect(builds[1]['tag_list']).to be_nil
          expect(builds[1]['script']).to match_array(["echo 'first hello'", "echo 'second hello'"])
        end

        perform!
      end

      context "with existing jobs from other project's alive pipelines" do
        before do
          create(:ci_pipeline, :with_job, user: user)
          create(:ci_pipeline, :with_job)
        end

        it 'returns the expected total_builds_count' do
          expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
            payload = Gitlab::Json.parse(params[:body])

            expect(payload['total_builds_count']).to eq(1)
          end

          perform!
        end
      end

      describe 'credit_card' do
        context 'with no registered credit_card' do
          it 'returns the expected credit card counts' do
            expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
              payload = Gitlab::Json.parse(params[:body])

              expect(payload['credit_card']['similar_cards_count']).to eq(0)
              expect(payload['credit_card']['similar_holder_names_count']).to eq(0)
            end

            perform!
          end
        end

        context 'with a registered credit card' do
          let!(:credit_card) { create(:credit_card_validation, last_digits: 10, holder_name: 'Alice', user: user) }

          it 'returns the expected credit card counts' do
            expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
              payload = Gitlab::Json.parse(params[:body])

              expect(payload['credit_card']['similar_cards_count']).to eq(1)
              expect(payload['credit_card']['similar_holder_names_count']).to eq(1)
            end

            perform!
          end

          context 'with similar credit cards registered by other users' do
            before do
              create(:credit_card_validation, last_digits: 10, holder_name: 'Bob')
            end

            it 'returns the expected credit card counts' do
              expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
                payload = Gitlab::Json.parse(params[:body])

                expect(payload['credit_card']['similar_cards_count']).to eq(2)
                expect(payload['credit_card']['similar_holder_names_count']).to eq(1)
              end

              perform!
            end
          end

          context 'with similar holder names registered by other users' do
            before do
              create(:credit_card_validation, last_digits: 11, holder_name: 'Alice')
            end

            it 'returns the expected credit card counts' do
              expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
                payload = Gitlab::Json.parse(params[:body])

                expect(payload['credit_card']['similar_cards_count']).to eq(1)
                expect(payload['credit_card']['similar_holder_names_count']).to eq(2)
              end

              perform!
            end
          end
        end
      end
    end

    context 'when EXTERNAL_VALIDATION_SERVICE_TOKEN is set' do
      before do
        stub_env('EXTERNAL_VALIDATION_SERVICE_TOKEN', '123')
      end

      it 'passes token in X-Gitlab-Token header' do
        expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
          expect(params[:headers]).to include({ 'X-Gitlab-Token' => '123' })
        end

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

    context 'when validation returns an HTTP 500 Error' do
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
        allow(Gitlab::AppLogger).to receive(:info)

        expect(Gitlab::AppLogger).to receive(:info).with(message: 'Pipeline not authorized', project_id: project.id, user_id: user.id)

        perform!
      end

      context 'when save_incompleted is false' do
        let(:save_incompleted) { false }

        it 'adds errors to the pipeline without persisting it', :aggregate_failures do
          perform!

          expect(pipeline).not_to be_persisted
          expect(pipeline.status).to eq('failed')
          expect(pipeline).to be_external_validation_failure
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
