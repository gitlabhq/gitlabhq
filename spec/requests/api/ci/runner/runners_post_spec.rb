# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :fleet_visibility do
  describe '/api/v4/runners' do
    let(:params) { nil }

    subject(:perform_request) do
      post api('/runners'), params: params
    end

    describe 'POST /api/v4/runners' do
      it_behaves_like 'runner migrations backoff' do
        let(:request) { perform_request }
      end

      context 'when no token is provided' do
        it 'returns 400 error' do
          perform_request

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when invalid token is provided' do
        let(:params) { { token: 'invalid' } }

        it 'returns 403 error' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('403 Forbidden - invalid token supplied')
        end
      end

      context 'when valid parameters are provided' do
        let(:new_runner) { build_stubbed(:ci_runner) }
        let(:params) do
          {
            token: 'valid token',
            description: 'server.hostname',
            maintenance_note: 'Some maintainer notes',
            run_untagged: false,
            tag_list: 'tag1, tag2',
            locked: true,
            paused: false,
            access_level: 'ref_protected',
            maximum_timeout: 9000
          }
        end

        before do
          expected_params = {
            description: 'server.hostname',
            maintenance_note: 'Some maintainer notes',
            run_untagged: false,
            tag_list: %w[tag1 tag2],
            locked: true,
            active: true,
            access_level: 'ref_protected',
            maximum_timeout: 9000
          }.stringify_keys

          allow_next_instance_of(
            ::Ci::Runners::RegisterRunnerService,
            'valid token',
            a_hash_including(expected_params)
          ) do |service|
            expect(service).to receive(:execute)
              .once
              .and_return(ServiceResponse.success(payload: { runner: new_runner }))
          end
        end

        context 'when token_expires_at is nil' do
          it 'creates runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq('id' => new_runner.id, 'token' => new_runner.token, 'token_expires_at' => nil)
          end
        end

        context 'when token_expires_at is a valid date' do
          before do
            new_runner.token_expires_at = Time.utc(2022, 1, 11, 14, 39, 24)
          end

          it 'creates runner' do
            perform_request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq(
              'id' => new_runner.id, 'token' => new_runner.token, 'token_expires_at' => '2022-01-11T14:39:24.000Z'
            )
          end
        end

        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { client_id: "runner/#{new_runner.id}" } }
        end

        it_behaves_like 'not executing any extra queries for the application context' do
          let(:subject_proc) { proc { perform_request } }
        end
      end

      context 'when deprecated maintainer_note field is provided' do
        RSpec::Matchers.define_negated_matcher :excluding, :include

        let(:new_runner) { create(:ci_runner) }
        let(:params) do
          {
            token: 'valid token',
            maintainer_note: 'Some maintainer notes'
          }
        end

        it 'converts to maintenance_note param' do
          allow_next_instance_of(
            ::Ci::Runners::RegisterRunnerService,
            'valid token',
            a_hash_including('maintenance_note' => 'Some maintainer notes')
              .and(excluding('maintainter_note' => anything))
          ) do |service|
            expect(service).to receive(:execute)
              .once
              .and_return(ServiceResponse.success(payload: { runner: new_runner }))
          end

          perform_request

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when deprecated active parameter is provided' do
        let_it_be(:new_runner) { build(:ci_runner) }

        let(:params) do
          {
            token: 'valid token',
            active: false
          }
        end

        it 'uses active value in registration' do
          expect_next_instance_of(
            ::Ci::Runners::RegisterRunnerService,
            'valid token',
            a_hash_including({ active: false }.stringify_keys)
          ) do |service|
            expect(service).to receive(:execute)
              .once
              .and_return(ServiceResponse.success(payload: { runner: new_runner }))
          end

          perform_request

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'calling actual register service' do
        include StubGitlabCalls

        let(:registration_token) { 'abcdefg123456' }

        before do
          stub_gitlab_calls
          stub_application_setting(runners_registration_token: registration_token)
          allow_any_instance_of(::Ci::Runner).to receive(:cache_attributes)
        end

        context 'when tags parameter is provided' do
          let(:params) do
            {
              token: registration_token,
              tag_list: tag_list
            }
          end

          context 'with number of tags above limit' do
            let(:tag_list) { (1..::Ci::Runner::TAG_LIST_MAX_LENGTH + 1).map { |i| "tag#{i}" } }

            it 'uses tag_list value in registration and returns error' do
              expect_next_instance_of(
                ::Ci::Runners::RegisterRunnerService,
                registration_token,
                a_hash_including({ tag_list: tag_list }.stringify_keys)
              ) do |service|
                expect(service).to receive(:execute)
                  .once
                  .and_call_original
              end

              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response.dig('message', 'tags_list')).to contain_exactly("Too many tags specified. Please limit the number of tags to #{::Ci::Runner::TAG_LIST_MAX_LENGTH}")
            end
          end

          context 'with number of tags below limit' do
            let(:tag_list) { (1..20).map { |i| "tag#{i}" } }

            it 'uses tag_list value in registration and successfully creates runner' do
              expect_next_instance_of(
                ::Ci::Runners::RegisterRunnerService,
                registration_token,
                a_hash_including({ tag_list: tag_list }.stringify_keys)
              ) do |service|
                expect(service).to receive(:execute)
                  .once
                  .and_call_original
              end

              perform_request

              expect(response).to have_gitlab_http_status(:created)
            end
          end
        end

        context 'when runner registration is disallowed' do
          before do
            stub_application_setting(allow_runner_registration_token: false)
          end

          it 'returns 410 Gone status' do
            post api('/runners'), params: { token: registration_token }

            expect(response).to have_gitlab_http_status(:gone)
          end
        end
      end
    end
  end
end
