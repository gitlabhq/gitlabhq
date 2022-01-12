# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state do
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
          allow_next_instance_of(::Ci::RegisterRunnerService) do |service|
            allow(service).to receive(:execute).and_return(nil)
          end

          post api('/runners'), params: { token: 'invalid' }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when valid parameters are provided' do
        def request
          post api('/runners'), params: {
            token: 'valid token',
            description: 'server.hostname',
            maintainer_note: 'Some maintainer notes',
            run_untagged: false,
            tag_list: 'tag1, tag2',
            locked: true,
            active: true,
            access_level: 'ref_protected',
            maximum_timeout: 9000
          }
        end

        let_it_be(:new_runner) { create(:ci_runner) }

        before do
          allow_next_instance_of(::Ci::RegisterRunnerService) do |service|
            expected_params = {
              description: 'server.hostname',
              maintainer_note: 'Some maintainer notes',
              run_untagged: false,
              tag_list: %w(tag1 tag2),
              locked: true,
              active: true,
              access_level: 'ref_protected',
              maximum_timeout: 9000
            }.stringify_keys

            allow(service).to receive(:execute)
              .once
              .with('valid token', a_hash_including(expected_params))
              .and_return(new_runner)
          end
        end

        it 'creates runner' do
          request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(new_runner.id)
          expect(json_response['token']).to eq(new_runner.token)
        end

        it_behaves_like 'storing arguments in the application context for the API' do
          subject { request }

          let(:expected_params) { { client_id: "runner/#{new_runner.id}" } }
        end

        it_behaves_like 'not executing any extra queries for the application context' do
          let(:subject_proc) { proc { request } }
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
      end
    end
  end
end
