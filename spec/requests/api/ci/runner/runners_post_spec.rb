# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_feature_flags(runner_registration_control: false)
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
    stub_application_setting(valid_runner_registrars: ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)
    allow_any_instance_of(::Ci::Runner).to receive(:cache_attributes)
  end

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
        end
      end

      context 'when valid token is provided' do
        def request
          post api('/runners'), params: { token: token }
        end

        context 'with a registration token' do
          let(:token) { registration_token }

          it 'creates runner with default values' do
            request

            runner = ::Ci::Runner.first

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['id']).to eq(runner.id)
            expect(json_response['token']).to eq(runner.token)
            expect(runner.run_untagged).to be true
            expect(runner.active).to be true
            expect(runner.token).not_to eq(registration_token)
            expect(runner).to be_instance_type
          end

          it_behaves_like 'storing arguments in the application context' do
            subject { request }

            let(:expected_params) { { client_id: "runner/#{::Ci::Runner.first.id}" } }
          end

          it_behaves_like 'not executing any extra queries for the application context' do
            let(:subject_proc) { proc { request } }
          end
        end

        context 'when project token is used' do
          let(:project) { create(:project) }
          let(:token) { project.runners_token }

          it 'creates project runner' do
            request

            expect(response).to have_gitlab_http_status(:created)
            expect(project.runners.size).to eq(1)
            runner = ::Ci::Runner.first
            expect(runner.token).not_to eq(registration_token)
            expect(runner.token).not_to eq(project.runners_token)
            expect(runner).to be_project_type
          end

          it_behaves_like 'storing arguments in the application context' do
            subject { request }

            let(:expected_params) { { project: project.full_path, client_id: "runner/#{::Ci::Runner.first.id}" } }
          end

          it_behaves_like 'not executing any extra queries for the application context' do
            let(:subject_proc) { proc { request } }
          end

          context 'when it exceeds the application limits' do
            before do
              create(:ci_runner, runner_type: :project_type, projects: [project], contacted_at: 1.second.ago)
              create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
            end

            it 'does not create runner' do
              request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to include('runner_projects.base' => ['Maximum number of ci registered project runners (1) exceeded'])
              expect(project.runners.reload.size).to eq(1)
            end
          end

          context 'when abandoned runners cause application limits to not be exceeded' do
            before do
              create(:ci_runner, runner_type: :project_type, projects: [project], created_at: 14.months.ago, contacted_at: 13.months.ago)
              create(:plan_limits, :default_plan, ci_registered_project_runners: 1)
            end

            it 'creates runner' do
              request

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['message']).to be_nil
              expect(project.runners.reload.size).to eq(2)
              expect(project.runners.recent.size).to eq(1)
            end
          end

          context 'when valid runner registrars do not include project' do
            before do
              stub_application_setting(valid_runner_registrars: ['group'])
            end

            context 'when feature flag is enabled' do
              before do
                stub_feature_flags(runner_registration_control: true)
              end

              it 'returns 403 error' do
                request

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end

            context 'when feature flag is disabled' do
              it 'registers the runner' do
                request

                expect(response).to have_gitlab_http_status(:created)
                expect(::Ci::Runner.first.active).to be true
              end
            end
          end
        end

        context 'when group token is used' do
          let(:group) { create(:group) }
          let(:token) { group.runners_token }

          it 'creates a group runner' do
            request

            expect(response).to have_gitlab_http_status(:created)
            expect(group.runners.reload.size).to eq(1)
            runner = ::Ci::Runner.first
            expect(runner.token).not_to eq(registration_token)
            expect(runner.token).not_to eq(group.runners_token)
            expect(runner).to be_group_type
          end

          it_behaves_like 'storing arguments in the application context' do
            subject { request }

            let(:expected_params) { { root_namespace: group.full_path_components.first, client_id: "runner/#{::Ci::Runner.first.id}" } }
          end

          it_behaves_like 'not executing any extra queries for the application context' do
            let(:subject_proc) { proc { request } }
          end

          context 'when it exceeds the application limits' do
            before do
              create(:ci_runner, runner_type: :group_type, groups: [group], contacted_at: nil, created_at: 1.month.ago)
              create(:plan_limits, :default_plan, ci_registered_group_runners: 1)
            end

            it 'does not create runner' do
              request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to include('runner_namespaces.base' => ['Maximum number of ci registered group runners (1) exceeded'])
              expect(group.runners.reload.size).to eq(1)
            end
          end

          context 'when abandoned runners cause application limits to not be exceeded' do
            before do
              create(:ci_runner, runner_type: :group_type, groups: [group], created_at: 4.months.ago, contacted_at: 3.months.ago)
              create(:ci_runner, runner_type: :group_type, groups: [group], contacted_at: nil, created_at: 4.months.ago)
              create(:plan_limits, :default_plan, ci_registered_group_runners: 1)
            end

            it 'creates runner' do
              request

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['message']).to be_nil
              expect(group.runners.reload.size).to eq(3)
              expect(group.runners.recent.size).to eq(1)
            end
          end

          context 'when valid runner registrars do not include group' do
            before do
              stub_application_setting(valid_runner_registrars: ['project'])
            end

            context 'when feature flag is enabled' do
              before do
                stub_feature_flags(runner_registration_control: true)
              end

              it 'returns 403 error' do
                request

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end

            context 'when feature flag is disabled' do
              it 'registers the runner' do
                request

                expect(response).to have_gitlab_http_status(:created)
                expect(::Ci::Runner.first.active).to be true
              end
            end
          end
        end
      end

      context 'when runner description is provided' do
        it 'creates runner' do
          post api('/runners'), params: {
                                  token: registration_token,
                                  description: 'server.hostname'
                                }

          expect(response).to have_gitlab_http_status(:created)
          expect(::Ci::Runner.first.description).to eq('server.hostname')
        end
      end

      context 'when runner tags are provided' do
        it 'creates runner' do
          post api('/runners'), params: {
                                  token: registration_token,
                                  tag_list: 'tag1, tag2'
                                }

          expect(response).to have_gitlab_http_status(:created)
          expect(::Ci::Runner.first.tag_list.sort).to eq(%w(tag1 tag2))
        end
      end

      context 'when option for running untagged jobs is provided' do
        context 'when tags are provided' do
          it 'creates runner' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    run_untagged: false,
                                    tag_list: ['tag']
                                  }

            expect(response).to have_gitlab_http_status(:created)
            expect(::Ci::Runner.first.run_untagged).to be false
            expect(::Ci::Runner.first.tag_list.sort).to eq(['tag'])
          end
        end

        context 'when tags are not provided' do
          it 'returns 400 error' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    run_untagged: false
                                  }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include(
              'tags_list' => ['can not be empty when runner is not allowed to pick untagged jobs'])
          end
        end
      end

      context 'when option for locking Runner is provided' do
        it 'creates runner' do
          post api('/runners'), params: {
                                  token: registration_token,
                                  locked: true
                                }

          expect(response).to have_gitlab_http_status(:created)
          expect(::Ci::Runner.first.locked).to be true
        end
      end

      context 'when option for activating a Runner is provided' do
        context 'when active is set to true' do
          it 'creates runner' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    active: true
                                  }

            expect(response).to have_gitlab_http_status(:created)
            expect(::Ci::Runner.first.active).to be true
          end
        end

        context 'when active is set to false' do
          it 'creates runner' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    active: false
                                  }

            expect(response).to have_gitlab_http_status(:created)
            expect(::Ci::Runner.first.active).to be false
          end
        end
      end

      context 'when access_level is provided for Runner' do
        context 'when access_level is set to ref_protected' do
          it 'creates runner' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    access_level: 'ref_protected'
                                  }

            expect(response).to have_gitlab_http_status(:created)
            expect(::Ci::Runner.first.ref_protected?).to be true
          end
        end

        context 'when access_level is set to not_protected' do
          it 'creates runner' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    access_level: 'not_protected'
                                  }

            expect(response).to have_gitlab_http_status(:created)
            expect(::Ci::Runner.first.ref_protected?).to be false
          end
        end
      end

      context 'when maximum job timeout is specified' do
        it 'creates runner' do
          post api('/runners'), params: {
                                  token: registration_token,
                                  maximum_timeout: 9000
                                }

          expect(response).to have_gitlab_http_status(:created)
          expect(::Ci::Runner.first.maximum_timeout).to eq(9000)
        end

        context 'when maximum job timeout is empty' do
          it 'creates runner' do
            post api('/runners'), params: {
                                    token: registration_token,
                                    maximum_timeout: ''
                                  }

            expect(response).to have_gitlab_http_status(:created)
            expect(::Ci::Runner.first.maximum_timeout).to be_nil
          end
        end
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
            expect(::Ci::Runner.first.read_attribute(param.to_sym)).to eq(value)
          end
        end
      end

      it "sets the runner's ip_address" do
        post api('/runners'),
             params: { token: registration_token },
             headers: { 'X-Forwarded-For' => '123.111.123.111' }

        expect(response).to have_gitlab_http_status(:created)
        expect(::Ci::Runner.first.ip_address).to eq('123.111.123.111')
      end
    end
  end
end
