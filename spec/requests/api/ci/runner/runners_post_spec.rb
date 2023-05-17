# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :runner_fleet do
  describe '/api/v4/runners' do
    describe 'POST /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/runners')

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/runners'), params: { token: 'invalid' }

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq('403 Forbidden - invalid token supplied')
        end
      end

      context 'when valid parameters are provided' do
        def request
          post api('/runners'), params: {
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

        let_it_be(:new_runner) { create(:ci_runner) }

        before do
          expected_params = {
            description: 'server.hostname',
            maintenance_note: 'Some maintainer notes',
            run_untagged: false,
            tag_list: %w(tag1 tag2),
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
            request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq({ 'id' => new_runner.id, 'token' => new_runner.token, 'token_expires_at' => nil })
          end
        end

        context 'when token_expires_at is a valid date' do
          before do
            new_runner.token_expires_at = DateTime.new(2022, 1, 11, 14, 39, 24)
          end

          it 'creates runner' do
            request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to eq({ 'id' => new_runner.id, 'token' => new_runner.token, 'token_expires_at' => '2022-01-11T14:39:24.000Z' })
          end
        end

        it_behaves_like 'storing arguments in the application context for the API' do
          subject { request }

          let(:expected_params) { { client_id: "runner/#{new_runner.id}" } }
        end

        it_behaves_like 'not executing any extra queries for the application context' do
          let(:subject_proc) { proc { request } }
        end
      end

      context 'when deprecated maintainer_note field is provided' do
        RSpec::Matchers.define_negated_matcher :excluding, :include

        def request
          post api('/runners'), params: {
            token: 'valid token',
            maintainer_note: 'Some maintainer notes'
          }
        end

        let(:new_runner) { create(:ci_runner) }

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

          request

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'when deprecated active parameter is provided' do
        def request
          post api('/runners'), params: {
            token: 'valid token',
            active: false
          }
        end

        let_it_be(:new_runner) { build(:ci_runner) }

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

          request

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

        %w(name version revision platform architecture).each do |param|
          context "when info parameter '#{param}' info is present" do
            let(:value) { "#{param}_value" }

            it "updates provided Runner's parameter" do
              post api('/runners'), params: {
                                      token: registration_token,
                                      info: { param => value }
                                    }

              expect(response).to have_gitlab_http_status(:created)
              expect(::Ci::Runner.last.read_attribute(param.to_sym)).to eq(value)
            end
          end
        end

        it "sets the runner's ip_address" do
          post api('/runners'),
               params: { token: registration_token },
               headers: { 'X-Forwarded-For' => '123.111.123.111' }

          expect(response).to have_gitlab_http_status(:created)
          expect(::Ci::Runner.last.ip_address).to eq('123.111.123.111')
        end

        context 'when tags parameter is provided' do
          def request
            post api('/runners'), params: {
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

              request

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

              request

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
