require 'spec_helper'

describe API::Runner do
  include ApiHelpers
  include StubGitlabCalls

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
  end

  describe '/api/v4/runners' do
    describe 'POST /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/runners')
          expect(response).to have_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/runners'), token: 'invalid'
          expect(response).to have_http_status 403
        end
      end

      context 'when valid token is provided' do
        it 'creates runner with default values' do
          post api('/runners'), token: registration_token

          runner = Ci::Runner.first

          expect(response).to have_http_status 201
          expect(json_response['id']).to eq(runner.id)
          expect(json_response['token']).to eq(runner.token)
          expect(runner.run_untagged).to be true
        end

        context 'when project token is used' do
          let(:project) { create(:empty_project) }

          it 'creates runner' do
            post api('/runners'), token: project.runners_token

            expect(response).to have_http_status 201
            expect(project.runners.size).to eq(1)
          end
        end
      end

      context 'when runner description is provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                description: 'server.hostname'

          expect(response).to have_http_status 201
          expect(Ci::Runner.first.description).to eq('server.hostname')
        end
      end

      context 'when runner tags are provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                tag_list: 'tag1, tag2'

          expect(response).to have_http_status 201
          expect(Ci::Runner.first.tag_list.sort).to eq(%w(tag1 tag2))
        end
      end

      context 'when option for running untagged jobs is provided' do
        context 'when tags are provided' do
          it 'creates runner' do
            post api('/runners'), token: registration_token,
                                  run_untagged: false,
                                  tag_list: ['tag']

            expect(response).to have_http_status 201
            expect(Ci::Runner.first.run_untagged).to be false
            expect(Ci::Runner.first.tag_list.sort).to eq(['tag'])
          end
        end

        context 'when tags are not provided' do
          it 'returns 404 error' do
            post api('/runners'), token: registration_token,
                                  run_untagged: false

            expect(response).to have_http_status 404
          end
        end
      end

      context 'when option for locking Runner is provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                locked: true

          expect(response).to have_http_status 201
          expect(Ci::Runner.first.locked).to be true
        end
      end

      %w(name version revision platform architecture).each do |param|
        context "when info parameter '#{param}' info is present" do
          let(:value) { "#{param}_value" }

          it %q(updates provided Runner's parameter) do
            post api('/runners'), token: registration_token,
                                  info: { param => value }

            expect(response).to have_http_status 201
            expect(Ci::Runner.first.read_attribute(param.to_sym)).to eq(value)
          end
        end
      end
    end

    describe 'DELETE /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          delete api('/runners')

          expect(response).to have_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          delete api('/runners'), token: 'invalid'

          expect(response).to have_http_status 403
        end
      end

      context 'when valid token is provided' do
        let(:runner) { create(:ci_runner) }

        it 'deletes Runner' do
          delete api('/runners'), token: runner.token

          expect(response).to have_http_status 204
          expect(Ci::Runner.count).to eq(0)
        end
      end
    end
  end

  describe '/api/v4/jobs' do
    let(:project) { create(:empty_project, shared_runners_enabled: false) }
    let(:pipeline) { create(:ci_pipeline_without_jobs, project: project, ref: 'master') }
    let(:runner) { create(:ci_runner) }
    let!(:job) { create(:ci_build, :artifacts, :extended_options, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0, commands: "ls\ndate") }

    before { project.runners << runner }

    describe 'POST /api/v4/jobs/request' do
      let!(:last_update) {}
      let!(:new_update) { }
      let(:user_agent) { 'gitlab-runner 9.0.0 (9-0-stable; go1.7.4; linux/amd64)' }

      before { stub_container_registry_config(enabled: false) }

      shared_examples 'no jobs available' do
        before { request_job }

        context 'when runner sends version in User-Agent' do
          context 'for stable version' do
            it 'gives 204 and set X-GitLab-Last-Update' do
              expect(response).to have_http_status(204)
              expect(response.header).to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when last_update is up-to-date' do
            let(:last_update) { runner.ensure_runner_queue_value }

            it 'gives 204 and set the same X-GitLab-Last-Update' do
              expect(response).to have_http_status(204)
              expect(response.header['X-GitLab-Last-Update']).to eq(last_update)
            end
          end

          context 'when last_update is outdated' do
            let(:last_update) { runner.ensure_runner_queue_value }
            let(:new_update) { runner.tick_runner_queue }

            it 'gives 204 and set a new X-GitLab-Last-Update' do
              expect(response).to have_http_status(204)
              expect(response.header['X-GitLab-Last-Update']).to eq(new_update)
            end
          end

          context 'for beta version' do
            let(:user_agent) { 'gitlab-runner 9.0.0~beta.167.g2b2bacc (master; go1.7.4; linux/amd64)' }
            it { expect(response).to have_http_status(204) }
          end

          context 'for pre-9-0 version' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0 (1-6-stable; go1.6.3; linux/amd64)' }
            it { expect(response).to have_http_status(204) }
          end

          context 'for pre-9-0 beta version' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0~beta.167.g2b2bacc (master; go1.6.3; linux/amd64)' }
            it { expect(response).to have_http_status(204) }
          end
        end

        context %q(when runner doesn't send version in User-Agent) do
          let(:user_agent) { 'Go-http-client/1.1' }
          it { expect(response).to have_http_status(404) }
        end

        context %q(when runner doesn't have a User-Agent) do
          let(:user_agent) { nil }
          it { expect(response).to have_http_status(404) }
        end
      end

      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/jobs/request')
          expect(response).to have_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/jobs/request'), token: 'invalid'
          expect(response).to have_http_status 403
        end
      end

      context 'when valid token is provided' do
        context 'when Runner is not active' do
          let(:runner) { create(:ci_runner, :inactive) }

          it 'returns 404 error' do
            request_job
            expect(response).to have_http_status 404
          end
        end

        context 'when jobs are finished' do
          before { job.success }
          it_behaves_like 'no jobs available'
        end

        context 'when other projects have pending jobs' do
          before do
            job.success
            create(:ci_build, :pending)
          end

          it_behaves_like 'no jobs available'
        end

        context 'when shared runner requests job for project without shared_runners_enabled' do
          let(:runner) { create(:ci_runner, :shared) }
          it_behaves_like 'no jobs available'
        end

        context 'when there is a pending job' do
          it 'starts a job' do
            request_job info: { platform: :darwin }

            expect(response).to have_http_status(201)
            expect(response.headers).not_to have_key('X-GitLab-Last-Update')
            expect(runner.reload.platform).to eq('darwin')

            expect(json_response['id']).to eq(job.id)
            expect(json_response['token']).to eq(job.token)
            expect(json_response['job_info']).to include({ 'name' => job.name },
                                                         { 'stage' => job.stage })
            expect(json_response['git_info']).to include({ 'sha' => job.sha },
                                                         { 'repo_url' => job.repo_url })
            expect(json_response['image']).to include({ 'name' => 'ruby:2.1' })
            expect(json_response['services']).to include({ 'name' => 'postgres' })
            expect(json_response['steps']).to include({ 'name' => 'after_script',
                                                        'script' => ['ls', 'date'],
                                                        'timeout' => job.timeout,
                                                        'condition' => Gitlab::Ci::Build::Response::Step::CONDITION_ALWAYS,
                                                        'result' => Gitlab::Ci::Build::Response::Step::RESULT_DOESNT_FAIL_JOB })
            expect(json_response['variables']).to include({ 'key' => 'CI_BUILD_NAME', 'value' => 'spinach', 'public' => true },
                                                          { 'key' => 'CI_BUILD_STAGE', 'value' => 'test', 'public' => true },
                                                          { 'key' => 'DB_NAME', 'value' => 'postgres', 'public' => true })
            expect(json_response['artifacts']).to include({ 'name' => 'artifacts_file' },
                                                          { 'paths' => ['out/'] })
          end

          context 'when job is made for tag' do
            let!(:job) { create(:ci_build_tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }

            it 'sets branch as ref_type' do
              request_job
              expect(response).to have_http_status(201)
              expect(json_response['git_info']['ref_type']).to eq('tag')
            end
          end

          context 'when job is made for branch' do
            it 'sets tag as ref_type' do
              request_job
              expect(response).to have_http_status(201)
              expect(json_response['git_info']['ref_type']).to eq('branch')
            end
          end

          it 'updates runner info' do
            expect { request_job }.to change { runner.reload.contacted_at }
          end

          %w(name version revision platform architecture).each do |param|
            context "when info parameter '#{param}' is present" do
              let(:value) { "#{param}_value" }

              it %q(updates provided Runner's parameter) do
                request_job info: { param => value }

                expect(response).to have_http_status(201)
                runner.reload
                expect(runner.read_attribute(param.to_sym)).to eq(value)
              end
            end
          end

          context 'when concurrently updating a job' do
            before do
              expect_any_instance_of(Ci::Build).to receive(:run!).
                  and_raise(ActiveRecord::StaleObjectError.new(nil, nil))
            end

            it 'returns a conflict' do
              request_job
              expect(response).to have_http_status(409)
              expect(response.headers).not_to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when project and pipeline have multiple jobs' do
            let!(:test_job) { create(:ci_build, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

            before { job.success }

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_http_status(201)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(1)
              expect(json_response['dependencies'][0]).to include('id' => job.id, 'name' => 'spinach')
            end
          end

          context 'when job has no tags' do
            before { job.update(tags: []) }

            context 'when runner is allowed to pick untagged jobs' do
              before { runner.update_column(:run_untagged, true) }

              it 'picks job' do
                request_job
                expect(response).to have_http_status 201
              end
            end

            context 'when runner is not allowed to pick untagged jobs' do
              before { runner.update_column(:run_untagged, false) }
              it_behaves_like 'no jobs available'
            end
          end

          context 'when triggered job is available' do
            before do
              trigger = create(:ci_trigger, project: project)
              create(:ci_trigger_request_with_variables, pipeline: pipeline, builds: [job], trigger: trigger)
              project.variables << Ci::Variable.new(key: 'SECRET_KEY', value: 'secret_value')
            end

            it 'returns variables for triggers' do
              request_job

              expect(response).to have_http_status(201)
              expect(json_response['variables']).to include({ 'key' => 'CI_BUILD_NAME', 'value' => 'spinach', 'public' => true },
                                                            { 'key' => 'CI_BUILD_STAGE', 'value' => 'test', 'public' => true },
                                                            { 'key' => 'CI_BUILD_TRIGGERED', 'value' => 'true', 'public' => true },
                                                            { 'key' => 'DB_NAME', 'value' => 'postgres', 'public' => true },
                                                            { 'key' => 'SECRET_KEY', 'value' => 'secret_value', 'public' => false },
                                                            { 'key' => 'TRIGGER_KEY_1', 'value' => 'TRIGGER_VALUE_1', 'public' => false })
            end
          end

          describe 'registry credentials support' do
            let(:registry_url) { 'registry.example.com:5005' }
            let(:registry_credentials) do
              { 'type' => 'registry',
                'url' => registry_url,
                'username' => 'gitlab-ci-token',
                'password' => job.token }
            end

            context 'when registry is enabled' do
              before { stub_container_registry_config(enabled: true, host_port: registry_url) }

              it 'sends registry credentials key' do
                request_job

                expect(json_response).to have_key('credentials')
                expect(json_response['credentials']).to include(registry_credentials)
              end
            end

            context 'when registry is disabled' do
              before { stub_container_registry_config(enabled: false, host_port: registry_url) }

              it 'does not send registry credentials' do
                request_job
                expect(json_response).to have_key('credentials')
                expect(json_response['credentials']).not_to include(registry_credentials)
              end
            end
          end
        end

        def request_job(token = runner.token, **params)
          new_params = params.merge(token: token, last_update: last_update)
          post api('/jobs/request'), new_params, { 'User-Agent' => user_agent }
        end
      end
    end
  end
end
