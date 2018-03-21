require 'spec_helper'

describe API::Runner do
  include StubGitlabCalls

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
    allow_any_instance_of(Ci::Runner).to receive(:cache_attributes)
  end

  describe '/api/v4/runners' do
    describe 'POST /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/runners')

          expect(response).to have_gitlab_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/runners'), token: 'invalid'

          expect(response).to have_gitlab_http_status 403
        end
      end

      context 'when valid token is provided' do
        it 'creates runner with default values' do
          post api('/runners'), token: registration_token

          runner = Ci::Runner.first

          expect(response).to have_gitlab_http_status 201
          expect(json_response['id']).to eq(runner.id)
          expect(json_response['token']).to eq(runner.token)
          expect(runner.run_untagged).to be true
          expect(runner.token).not_to eq(registration_token)
        end

        context 'when project token is used' do
          let(:project) { create(:project) }

          it 'creates runner' do
            post api('/runners'), token: project.runners_token

            expect(response).to have_gitlab_http_status 201
            expect(project.runners.size).to eq(1)
            expect(Ci::Runner.first.token).not_to eq(registration_token)
            expect(Ci::Runner.first.token).not_to eq(project.runners_token)
          end
        end
      end

      context 'when runner description is provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                description: 'server.hostname'

          expect(response).to have_gitlab_http_status 201
          expect(Ci::Runner.first.description).to eq('server.hostname')
        end
      end

      context 'when runner tags are provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                tag_list: 'tag1, tag2'

          expect(response).to have_gitlab_http_status 201
          expect(Ci::Runner.first.tag_list.sort).to eq(%w(tag1 tag2))
        end
      end

      context 'when option for running untagged jobs is provided' do
        context 'when tags are provided' do
          it 'creates runner' do
            post api('/runners'), token: registration_token,
                                  run_untagged: false,
                                  tag_list: ['tag']

            expect(response).to have_gitlab_http_status 201
            expect(Ci::Runner.first.run_untagged).to be false
            expect(Ci::Runner.first.tag_list.sort).to eq(['tag'])
          end
        end

        context 'when tags are not provided' do
          it 'returns 404 error' do
            post api('/runners'), token: registration_token,
                                  run_untagged: false

            expect(response).to have_gitlab_http_status 404
          end
        end
      end

      context 'when option for locking Runner is provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                locked: true

          expect(response).to have_gitlab_http_status 201
          expect(Ci::Runner.first.locked).to be true
        end
      end

      context 'when maximum job timeout is specified' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                maximum_timeout: 9000

          expect(response).to have_gitlab_http_status 201
          expect(Ci::Runner.first.maximum_timeout).to eq(9000)
        end

        context 'when maximum job timeout is empty' do
          it 'creates runner' do
            post api('/runners'), token: registration_token,
                                  maximum_timeout: ''

            expect(response).to have_gitlab_http_status 201
            expect(Ci::Runner.first.maximum_timeout).to be_nil
          end
        end
      end

      %w(name version revision platform architecture).each do |param|
        context "when info parameter '#{param}' info is present" do
          let(:value) { "#{param}_value" }

          it "updates provided Runner's parameter" do
            post api('/runners'), token: registration_token,
                                  info: { param => value }

            expect(response).to have_gitlab_http_status 201
            expect(Ci::Runner.first.read_attribute(param.to_sym)).to eq(value)
          end
        end
      end

      it "sets the runner's ip_address" do
        post api('/runners'),
          { token: registration_token },
          { 'REMOTE_ADDR' => '123.111.123.111' }

        expect(response).to have_gitlab_http_status 201
        expect(Ci::Runner.first.ip_address).to eq('123.111.123.111')
      end
    end

    describe 'DELETE /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          delete api('/runners')

          expect(response).to have_gitlab_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          delete api('/runners'), token: 'invalid'

          expect(response).to have_gitlab_http_status 403
        end
      end

      context 'when valid token is provided' do
        let(:runner) { create(:ci_runner) }

        it 'deletes Runner' do
          delete api('/runners'), token: runner.token

          expect(response).to have_gitlab_http_status 204
          expect(Ci::Runner.count).to eq(0)
        end

        it_behaves_like '412 response' do
          let(:request) { api('/runners') }
          let(:params) { { token: runner.token } }
        end
      end
    end

    describe 'POST /api/v4/runners/verify' do
      let(:runner) { create(:ci_runner) }

      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/runners/verify')

          expect(response).to have_gitlab_http_status :bad_request
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/runners/verify'), token: 'invalid-token'

          expect(response).to have_gitlab_http_status 403
        end
      end

      context 'when valid token is provided' do
        it 'verifies Runner credentials' do
          post api('/runners/verify'), token: runner.token

          expect(response).to have_gitlab_http_status 200
        end
      end
    end
  end

  describe '/api/v4/jobs' do
    let(:project) { create(:project, shared_runners_enabled: false) }
    let(:pipeline) { create(:ci_pipeline_without_jobs, project: project, ref: 'master') }
    let(:runner) { create(:ci_runner) }
    let(:job) do
      create(:ci_build, :artifacts, :extended_options,
             pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0, commands: "ls\ndate")
    end

    before do
      project.runners << runner
    end

    describe 'POST /api/v4/jobs/request' do
      let!(:last_update) {}
      let!(:new_update) { }
      let(:user_agent) { 'gitlab-runner 9.0.0 (9-0-stable; go1.7.4; linux/amd64)' }

      before do
        job
        stub_container_registry_config(enabled: false)
      end

      shared_examples 'no jobs available' do
        before do
          request_job
        end

        context 'when runner sends version in User-Agent' do
          context 'for stable version' do
            it 'gives 204 and set X-GitLab-Last-Update' do
              expect(response).to have_gitlab_http_status(204)
              expect(response.header).to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when last_update is up-to-date' do
            let(:last_update) { runner.ensure_runner_queue_value }

            it 'gives 204 and set the same X-GitLab-Last-Update' do
              expect(response).to have_gitlab_http_status(204)
              expect(response.header['X-GitLab-Last-Update']).to eq(last_update)
            end
          end

          context 'when last_update is outdated' do
            let(:last_update) { runner.ensure_runner_queue_value }
            let(:new_update) { runner.tick_runner_queue }

            it 'gives 204 and set a new X-GitLab-Last-Update' do
              expect(response).to have_gitlab_http_status(204)
              expect(response.header['X-GitLab-Last-Update']).to eq(new_update)
            end
          end

          context 'when beta version is sent' do
            let(:user_agent) { 'gitlab-runner 9.0.0~beta.167.g2b2bacc (master; go1.7.4; linux/amd64)' }

            it { expect(response).to have_gitlab_http_status(204) }
          end

          context 'when pre-9-0 version is sent' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0 (1-6-stable; go1.6.3; linux/amd64)' }

            it { expect(response).to have_gitlab_http_status(204) }
          end

          context 'when pre-9-0 beta version is sent' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0~beta.167.g2b2bacc (master; go1.6.3; linux/amd64)' }

            it { expect(response).to have_gitlab_http_status(204) }
          end
        end
      end

      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/jobs/request')

          expect(response).to have_gitlab_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/jobs/request'), token: 'invalid'

          expect(response).to have_gitlab_http_status 403
        end
      end

      context 'when valid token is provided' do
        context 'when Runner is not active' do
          let(:runner) { create(:ci_runner, :inactive) }

          it 'returns 204 error' do
            request_job

            expect(response).to have_gitlab_http_status 204
          end
        end

        context 'when jobs are finished' do
          before do
            job.success
          end

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
          let(:expected_job_info) do
            { 'name' => job.name,
              'stage' => job.stage,
              'project_id' => job.project.id,
              'project_name' => job.project.name }
          end

          let(:expected_git_info) do
            { 'repo_url' => job.repo_url,
              'ref' => job.ref,
              'sha' => job.sha,
              'before_sha' => job.before_sha,
              'ref_type' => 'branch' }
          end

          let(:expected_steps) do
            [{ 'name' => 'script',
               'script' => %w(ls date),
               'timeout' => job.timeout,
               'when' => 'on_success',
               'allow_failure' => false },
             { 'name' => 'after_script',
               'script' => %w(ls date),
               'timeout' => job.timeout,
               'when' => 'always',
               'allow_failure' => true }]
          end

          let(:expected_variables) do
            [{ 'key' => 'CI_JOB_NAME', 'value' => 'spinach', 'public' => true },
             { 'key' => 'CI_JOB_STAGE', 'value' => 'test', 'public' => true },
             { 'key' => 'DB_NAME', 'value' => 'postgres', 'public' => true }]
          end

          let(:expected_artifacts) do
            [{ 'name' => 'artifacts_file',
               'untracked' => false,
               'paths' => %w(out/),
               'when' => 'always',
               'expire_in' => '7d' }]
          end

          let(:expected_cache) do
            [{ 'key' => 'cache_key',
               'untracked' => false,
               'paths' => ['vendor/*'],
               'policy' => 'pull-push' }]
          end

          let(:expected_features) { { 'trace_sections' => true } }

          it 'picks a job' do
            request_job info: { platform: :darwin }

            expect(response).to have_gitlab_http_status(201)
            expect(response.headers).not_to have_key('X-GitLab-Last-Update')
            expect(runner.reload.platform).to eq('darwin')
            expect(json_response['id']).to eq(job.id)
            expect(json_response['token']).to eq(job.token)
            expect(json_response['job_info']).to eq(expected_job_info)
            expect(json_response['git_info']).to eq(expected_git_info)
            expect(json_response['image']).to eq({ 'name' => 'ruby:2.1', 'entrypoint' => '/bin/sh' })
            expect(json_response['services']).to eq([{ 'name' => 'postgres', 'entrypoint' => nil,
                                                       'alias' => nil, 'command' => nil },
                                                     { 'name' => 'docker:dind', 'entrypoint' => '/bin/sh',
                                                       'alias' => 'docker', 'command' => 'sleep 30' }])
            expect(json_response['steps']).to eq(expected_steps)
            expect(json_response['artifacts']).to eq(expected_artifacts)
            expect(json_response['cache']).to eq(expected_cache)
            expect(json_response['variables']).to include(*expected_variables)
            expect(json_response['features']).to eq(expected_features)
          end

          context 'when job is made for tag' do
            let!(:job) { create(:ci_build, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }

            it 'sets branch as ref_type' do
              request_job

              expect(response).to have_gitlab_http_status(201)
              expect(json_response['git_info']['ref_type']).to eq('tag')
            end
          end

          context 'when job is made for branch' do
            it 'sets tag as ref_type' do
              request_job

              expect(response).to have_gitlab_http_status(201)
              expect(json_response['git_info']['ref_type']).to eq('branch')
            end
          end

          it 'updates runner info' do
            expect { request_job }.to change { runner.reload.contacted_at }
          end

          %w(version revision platform architecture).each do |param|
            context "when info parameter '#{param}' is present" do
              let(:value) { "#{param}_value" }

              it "updates provided Runner's parameter" do
                request_job info: { param => value }

                expect(response).to have_gitlab_http_status(201)
                expect(runner.reload.read_attribute(param.to_sym)).to eq(value)
              end
            end
          end

          it "sets the runner's ip_address" do
            post api('/jobs/request'),
              { token: runner.token },
              { 'User-Agent' => user_agent, 'REMOTE_ADDR' => '123.222.123.222' }

            expect(response).to have_gitlab_http_status 201
            expect(runner.reload.ip_address).to eq('123.222.123.222')
          end

          context 'when concurrently updating a job' do
            before do
              expect_any_instance_of(Ci::Build).to receive(:run!)
                  .and_raise(ActiveRecord::StaleObjectError.new(nil, nil))
            end

            it 'returns a conflict' do
              request_job

              expect(response).to have_gitlab_http_status(409)
              expect(response.headers).not_to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when project and pipeline have multiple jobs' do
            let!(:job) { create(:ci_build, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:job2) { create(:ci_build, :tag, pipeline: pipeline, name: 'rubocop', stage: 'test', stage_idx: 0) }
            let!(:test_job) { create(:ci_build, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

            before do
              job.success
              job2.success
            end

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_gitlab_http_status(201)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(2)
              expect(json_response['dependencies']).to include(
                { 'id' => job.id, 'name' => job.name, 'token' => job.token },
                { 'id' => job2.id, 'name' => job2.name, 'token' => job2.token })
            end
          end

          context 'when pipeline have jobs with artifacts' do
            let!(:job) { create(:ci_build, :tag, :artifacts, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:test_job) { create(:ci_build, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

            before do
              job.success
            end

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_gitlab_http_status(201)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(1)
              expect(json_response['dependencies']).to include(
                { 'id' => job.id, 'name' => job.name, 'token' => job.token,
                  'artifacts_file' => { 'filename' => 'ci_build_artifacts.zip', 'size' => 106365 } })
            end
          end

          context 'when explicit dependencies are defined' do
            let!(:job) { create(:ci_build, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:job2) { create(:ci_build, :tag, pipeline: pipeline, name: 'rubocop', stage: 'test', stage_idx: 0) }
            let!(:test_job) do
              create(:ci_build, pipeline: pipeline, token: 'test-job-token', name: 'deploy',
                                stage: 'deploy', stage_idx: 1,
                                options: { dependencies: [job2.name] })
            end

            before do
              job.success
              job2.success
            end

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_gitlab_http_status(201)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(1)
              expect(json_response['dependencies'][0]).to include('id' => job2.id, 'name' => job2.name, 'token' => job2.token)
            end
          end

          context 'when dependencies is an empty array' do
            let!(:job) { create(:ci_build, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:job2) { create(:ci_build, :tag, pipeline: pipeline, name: 'rubocop', stage: 'test', stage_idx: 0) }
            let!(:empty_dependencies_job) do
              create(:ci_build, pipeline: pipeline, token: 'test-job-token', name: 'empty_dependencies_job',
                                stage: 'deploy', stage_idx: 1,
                                options: { dependencies: [] })
            end

            before do
              job.success
              job2.success
            end

            it 'returns an empty array' do
              request_job

              expect(response).to have_gitlab_http_status(201)
              expect(json_response['id']).to eq(empty_dependencies_job.id)
              expect(json_response['dependencies'].count).to eq(0)
            end
          end

          context 'when job has no tags' do
            before do
              job.update(tags: [])
            end

            context 'when runner is allowed to pick untagged jobs' do
              before do
                runner.update_column(:run_untagged, true)
              end

              it 'picks job' do
                request_job

                expect(response).to have_gitlab_http_status 201
              end
            end

            context 'when runner is not allowed to pick untagged jobs' do
              before do
                runner.update_column(:run_untagged, false)
              end

              it_behaves_like 'no jobs available'
            end
          end

          context 'when triggered job is available' do
            let(:expected_variables) do
              [{ 'key' => 'CI_JOB_NAME', 'value' => 'spinach', 'public' => true },
               { 'key' => 'CI_JOB_STAGE', 'value' => 'test', 'public' => true },
               { 'key' => 'CI_PIPELINE_TRIGGERED', 'value' => 'true', 'public' => true },
               { 'key' => 'DB_NAME', 'value' => 'postgres', 'public' => true },
               { 'key' => 'SECRET_KEY', 'value' => 'secret_value', 'public' => false },
               { 'key' => 'TRIGGER_KEY_1', 'value' => 'TRIGGER_VALUE_1', 'public' => false }]
            end

            let(:trigger) { create(:ci_trigger, project: project) }
            let!(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, builds: [job], trigger: trigger) }

            before do
              project.variables << Ci::Variable.new(key: 'SECRET_KEY', value: 'secret_value')
            end

            shared_examples 'expected variables behavior' do
              it 'returns variables for triggers' do
                request_job

                expect(response).to have_gitlab_http_status(201)
                expect(json_response['variables']).to include(*expected_variables)
              end
            end

            context 'when variables are stored in trigger_request' do
              before do
                trigger_request.update_attribute(:variables, { TRIGGER_KEY_1: 'TRIGGER_VALUE_1' } )
              end

              it_behaves_like 'expected variables behavior'
            end

            context 'when variables are stored in pipeline_variables' do
              before do
                create(:ci_pipeline_variable, pipeline: pipeline, key: :TRIGGER_KEY_1, value: 'TRIGGER_VALUE_1')
              end

              it_behaves_like 'expected variables behavior'
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
              before do
                stub_container_registry_config(enabled: true, host_port: registry_url)
              end

              it 'sends registry credentials key' do
                request_job

                expect(json_response).to have_key('credentials')
                expect(json_response['credentials']).to include(registry_credentials)
              end
            end

            context 'when registry is disabled' do
              before do
                stub_container_registry_config(enabled: false, host_port: registry_url)
              end

              it 'does not send registry credentials' do
                request_job

                expect(json_response).to have_key('credentials')
                expect(json_response['credentials']).not_to include(registry_credentials)
              end
            end
          end

          describe 'timeout support' do
            context 'when project specifies job timeout' do
              let(:project) { create(:project, shared_runners_enabled: false, build_timeout: 1234) }

              it 'contains info about timeout taken from project' do
                request_job

                expect(response).to have_gitlab_http_status(201)
                expect(json_response['runner_info']).to include({ 'timeout' => 1234 })
              end

              context 'when runner specifies lower timeout' do
                let(:runner) { create(:ci_runner, maximum_timeout: 1000) }

                it 'contains info about timeout overridden by runner' do
                  request_job

                  expect(response).to have_gitlab_http_status(201)
                  expect(json_response['runner_info']).to include({ 'timeout' => 1000 })
                end
              end

              context 'when runner specifies bigger timeout' do
                let(:runner) { create(:ci_runner, maximum_timeout: 2000) }

                it 'contains info about timeout not overridden by runner' do
                  request_job

                  expect(response).to have_gitlab_http_status(201)
                  expect(json_response['runner_info']).to include({ 'timeout' => 1234 })
                end
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

    describe 'PUT /api/v4/jobs/:id' do
      let(:job) { create(:ci_build, :pending, :trace_live, pipeline: pipeline, runner_id: runner.id) }

      before do
        job.run!
      end

      context 'when status is given' do
        it 'mark job as succeeded' do
          update_job(state: 'success')

          job.reload
          expect(job).to be_success
        end

        it 'mark job as failed' do
          update_job(state: 'failed')

          job.reload
          expect(job).to be_failed
          expect(job).to be_unknown_failure
        end

        context 'when failure_reason is script_failure' do
          before do
            update_job(state: 'failed', failure_reason: 'script_failure')
            job.reload
          end

          it { expect(job).to be_script_failure }
        end

        context 'when failure_reason is runner_system_failure' do
          before do
            update_job(state: 'failed', failure_reason: 'runner_system_failure')
            job.reload
          end

          it { expect(job).to be_runner_system_failure }
        end
      end

      context 'when trace is given' do
        it 'creates a trace artifact' do
          allow(BuildFinishedWorker).to receive(:perform_async).with(job.id) do
            ArchiveTraceWorker.new.perform(job.id)
          end

          update_job(state: 'success', trace: 'BUILD TRACE UPDATED')

          job.reload
          expect(response).to have_gitlab_http_status(200)
          expect(job.trace.raw).to eq 'BUILD TRACE UPDATED'
          expect(job.job_artifacts_trace.open.read).to eq 'BUILD TRACE UPDATED'
        end
      end

      context 'when no trace is given' do
        it 'does not override trace information' do
          update_job

          expect(job.reload.trace.raw).to eq 'BUILD TRACE'
        end
      end

      context 'when job has been erased' do
        let(:job) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it 'responds with forbidden' do
          update_job

          expect(response).to have_gitlab_http_status(403)
        end
      end

      def update_job(token = job.token, **params)
        new_params = params.merge(token: token)
        put api("/jobs/#{job.id}"), new_params
      end
    end

    describe 'PATCH /api/v4/jobs/:id/trace' do
      let(:job) { create(:ci_build, :running, :trace_live, runner_id: runner.id, pipeline: pipeline) }
      let(:headers) { { API::Helpers::Runner::JOB_TOKEN_HEADER => job.token, 'Content-Type' => 'text/plain' } }
      let(:headers_with_range) { headers.merge({ 'Content-Range' => '11-20' }) }
      let(:update_interval) { 10.seconds.to_i }

      before do
        initial_patch_the_trace
      end

      context 'when request is valid' do
        it 'gets correct response' do
          expect(response.status).to eq 202
          expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'Job-Status'
        end

        context 'when job has been updated recently' do
          it { expect { patch_the_trace }.not_to change { job.updated_at }}

          it "changes the job's trace" do
            patch_the_trace

            expect(job.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when Runner makes a force-patch' do
            it { expect { force_patch_the_trace }.not_to change { job.updated_at }}

            it "doesn't change the build.trace" do
              force_patch_the_trace

              expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
            end
          end
        end

        context 'when job was not updated recently' do
          let(:update_interval) { 15.minutes.to_i }

          it { expect { patch_the_trace }.to change { job.updated_at } }

          it 'changes the job.trace' do
            patch_the_trace

            expect(job.reload.trace.raw).to eq 'BUILD TRACE appended appended'
          end

          context 'when Runner makes a force-patch' do
            it { expect { force_patch_the_trace }.to change { job.updated_at } }

            it "doesn't change the job.trace" do
              force_patch_the_trace

              expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
            end
          end
        end

        context 'when project for the build has been deleted' do
          let(:job) do
            create(:ci_build, :running, :trace_live, runner_id: runner.id, pipeline: pipeline) do |job|
              job.project.update(pending_delete: true)
            end
          end

          it 'responds with forbidden' do
            expect(response.status).to eq(403)
          end
        end
      end

      context 'when Runner makes a force-patch' do
        before do
          force_patch_the_trace
        end

        it 'gets correct response' do
          expect(response.status).to eq 202
          expect(job.reload.trace.raw).to eq 'BUILD TRACE appended'
          expect(response.header).to have_key 'Range'
          expect(response.header).to have_key 'Job-Status'
        end
      end

      context 'when content-range start is too big' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '15-20' }) }

        it 'gets 416 error response with range headers' do
          expect(response.status).to eq 416
          expect(response.header).to have_key 'Range'
          expect(response.header['Range']).to eq '0-11'
        end
      end

      context 'when content-range start is too small' do
        let(:headers_with_range) { headers.merge({ 'Content-Range' => '8-20' }) }

        it 'gets 416 error response with range headers' do
          expect(response.status).to eq 416
          expect(response.header).to have_key 'Range'
          expect(response.header['Range']).to eq '0-11'
        end
      end

      context 'when Content-Range header is missing' do
        let(:headers_with_range) { headers }

        it { expect(response.status).to eq 400 }
      end

      context 'when job has been errased' do
        let(:job) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it { expect(response.status).to eq 403 }
      end

      def patch_the_trace(content = ' appended', request_headers = nil)
        unless request_headers
          job.trace.read do |stream|
            offset = stream.size
            limit = offset + content.length - 1
            request_headers = headers.merge({ 'Content-Range' => "#{offset}-#{limit}" })
          end
        end

        Timecop.travel(job.updated_at + update_interval) do
          patch api("/jobs/#{job.id}/trace"), content, request_headers
          job.reload
        end
      end

      def initial_patch_the_trace
        patch_the_trace(' appended', headers_with_range)
      end

      def force_patch_the_trace
        2.times { patch_the_trace('') }
      end
    end

    describe 'artifacts' do
      let(:job) { create(:ci_build, :pending, pipeline: pipeline, runner_id: runner.id) }
      let(:jwt_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
      let(:headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => jwt_token } }
      let(:headers_with_token) { headers.merge(API::Helpers::Runner::JOB_TOKEN_HEADER => job.token) }
      let(:file_upload) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
      let(:file_upload2) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/gif') }

      before do
        stub_artifacts_object_storage
        job.run!
      end

      describe 'POST /api/v4/jobs/:id/artifacts/authorize' do
        context 'when using token as parameter' do
          it 'authorizes posting artifacts to running job' do
            authorize_artifacts_with_token_in_params

            expect(response).to have_gitlab_http_status(200)
            expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            expect(json_response['TempPath']).not_to be_nil
          end

          it 'fails to post too large artifact' do
            stub_application_setting(max_artifacts_size: 0)

            authorize_artifacts_with_token_in_params(filesize: 100)

            expect(response).to have_gitlab_http_status(413)
          end
        end

        context 'when using token as header' do
          it 'authorizes posting artifacts to running job' do
            authorize_artifacts_with_token_in_headers

            expect(response).to have_gitlab_http_status(200)
            expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            expect(json_response['TempPath']).not_to be_nil
          end

          it 'fails to post too large artifact' do
            stub_application_setting(max_artifacts_size: 0)

            authorize_artifacts_with_token_in_headers(filesize: 100)

            expect(response).to have_gitlab_http_status(413)
          end
        end

        context 'when using runners token' do
          it 'fails to authorize artifacts posting' do
            authorize_artifacts(token: job.project.runners_token)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        it 'reject requests that did not go through gitlab-workhorse' do
          headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

          authorize_artifacts

          expect(response).to have_gitlab_http_status(500)
        end

        context 'authorization token is invalid' do
          it 'responds with forbidden' do
            authorize_artifacts(token: 'invalid', filesize: 100 )

            expect(response).to have_gitlab_http_status(403)
          end
        end

        def authorize_artifacts(params = {}, request_headers = headers)
          post api("/jobs/#{job.id}/artifacts/authorize"), params, request_headers
        end

        def authorize_artifacts_with_token_in_params(params = {}, request_headers = headers)
          params = params.merge(token: job.token)
          authorize_artifacts(params, request_headers)
        end

        def authorize_artifacts_with_token_in_headers(params = {}, request_headers = headers_with_token)
          authorize_artifacts(params, request_headers)
        end
      end

      describe 'POST /api/v4/jobs/:id/artifacts' do
        context 'when artifacts are being stored inside of tmp path' do
          before do
            # by configuring this path we allow to pass temp file from any path
            allow(JobArtifactUploader).to receive(:workhorse_upload_path).and_return('/')
          end

          context 'when job has been erased' do
            let(:job) { create(:ci_build, erased_at: Time.now) }

            before do
              upload_artifacts(file_upload, headers_with_token)
            end

            it 'responds with forbidden' do
              upload_artifacts(file_upload, headers_with_token)

              expect(response).to have_gitlab_http_status(403)
            end
          end

          context 'when job is running' do
            shared_examples 'successful artifacts upload' do
              it 'updates successfully' do
                expect(response).to have_gitlab_http_status(201)
              end
            end

            context 'when uses regular file post' do
              before do
                upload_artifacts(file_upload, headers_with_token, false)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'when uses accelerated file post' do
              before do
                upload_artifacts(file_upload, headers_with_token, true)
              end

              it_behaves_like 'successful artifacts upload'
            end

            context 'when using runners token' do
              it 'responds with forbidden' do
                upload_artifacts(file_upload, headers.merge(API::Helpers::Runner::JOB_TOKEN_HEADER => job.project.runners_token))

                expect(response).to have_gitlab_http_status(403)
              end
            end
          end

          context 'when artifacts file is too large' do
            it 'fails to post too large artifact' do
              stub_application_setting(max_artifacts_size: 0)

              upload_artifacts(file_upload, headers_with_token)

              expect(response).to have_gitlab_http_status(413)
            end
          end

          context 'when artifacts post request does not contain file' do
            it 'fails to post artifacts without file' do
              post api("/jobs/#{job.id}/artifacts"), {}, headers_with_token

              expect(response).to have_gitlab_http_status(400)
            end
          end

          context 'GitLab Workhorse is not configured' do
            it 'fails to post artifacts without GitLab-Workhorse' do
              post api("/jobs/#{job.id}/artifacts"), { token: job.token }, {}

              expect(response).to have_gitlab_http_status(403)
            end
          end

          context 'when setting an expire date' do
            let(:default_artifacts_expire_in) {}
            let(:post_data) do
              { 'file.path' => file_upload.path,
                'file.name' => file_upload.original_filename,
                'expire_in' => expire_in }
            end

            before do
              stub_application_setting(default_artifacts_expire_in: default_artifacts_expire_in)

              post(api("/jobs/#{job.id}/artifacts"), post_data, headers_with_token)
            end

            context 'when an expire_in is given' do
              let(:expire_in) { '7 days' }

              it 'updates when specified' do
                expect(response).to have_gitlab_http_status(201)
                expect(job.reload.artifacts_expire_at).to be_within(5.minutes).of(7.days.from_now)
              end
            end

            context 'when no expire_in is given' do
              let(:expire_in) { nil }

              it 'ignores if not specified' do
                expect(response).to have_gitlab_http_status(201)
                expect(job.reload.artifacts_expire_at).to be_nil
              end

              context 'with application default' do
                context 'when default is 5 days' do
                  let(:default_artifacts_expire_in) { '5 days' }

                  it 'sets to application default' do
                    expect(response).to have_gitlab_http_status(201)
                    expect(job.reload.artifacts_expire_at).to be_within(5.minutes).of(5.days.from_now)
                  end
                end

                context 'when default is 0' do
                  let(:default_artifacts_expire_in) { '0' }

                  it 'does not set expire_in' do
                    expect(response).to have_gitlab_http_status(201)
                    expect(job.reload.artifacts_expire_at).to be_nil
                  end
                end
              end
            end
          end

          context 'posts artifacts file and metadata file' do
            let!(:artifacts) { file_upload }
            let!(:artifacts_sha256) { Digest::SHA256.file(artifacts.path).hexdigest }
            let!(:metadata) { file_upload2 }

            let(:stored_artifacts_file) { job.reload.artifacts_file.file }
            let(:stored_metadata_file) { job.reload.artifacts_metadata.file }
            let(:stored_artifacts_size) { job.reload.artifacts_size }
            let(:stored_artifacts_sha256) { job.reload.job_artifacts_archive.file_sha256 }

            before do
              post(api("/jobs/#{job.id}/artifacts"), post_data, headers_with_token)
            end

            context 'when posts data accelerated by workhorse is correct' do
              let(:post_data) do
                { 'file.path' => artifacts.path,
                  'file.name' => artifacts.original_filename,
                  'file.sha256' => artifacts_sha256,
                  'metadata.path' => metadata.path,
                  'metadata.name' => metadata.original_filename }
              end

              it 'stores artifacts and artifacts metadata' do
                expect(response).to have_gitlab_http_status(201)
                expect(stored_artifacts_file.original_filename).to eq(artifacts.original_filename)
                expect(stored_metadata_file.original_filename).to eq(metadata.original_filename)
                expect(stored_artifacts_size).to eq(72821)
                expect(stored_artifacts_sha256).to eq(artifacts_sha256)
              end
            end

            context 'when there is no artifacts file in post data' do
              let(:post_data) do
                { 'metadata' => metadata }
              end

              it 'is expected to respond with bad request' do
                expect(response).to have_gitlab_http_status(400)
              end

              it 'does not store metadata' do
                expect(stored_metadata_file).to be_nil
              end
            end
          end
        end

        context 'when artifacts are being stored outside of tmp path' do
          before do
            # by configuring this path we allow to pass file from @tmpdir only
            # but all temporary files are stored in system tmp directory
            @tmpdir = Dir.mktmpdir
            allow(JobArtifactUploader).to receive(:workhorse_upload_path).and_return(@tmpdir)
          end

          after do
            FileUtils.remove_entry @tmpdir
          end

          it' "fails to post artifacts for outside of tmp path"' do
            upload_artifacts(file_upload, headers_with_token)

            expect(response).to have_gitlab_http_status(400)
          end
        end

        def upload_artifacts(file, headers = {}, accelerated = true)
          params = if accelerated
                     { 'file.path' => file.path, 'file.name' => file.original_filename }
                   else
                     { 'file' => file }
                   end

          post api("/jobs/#{job.id}/artifacts"), params, headers
        end
      end

      describe 'GET /api/v4/jobs/:id/artifacts' do
        let(:token) { job.token }

        context 'when job has artifacts' do
          let(:job) { create(:ci_build) }
          let(:store) { JobArtifactUploader::Store::LOCAL }

          before do
            create(:ci_job_artifact, :archive, file_store: store, job: job)
          end

          context 'when using job token' do
            context 'when artifacts are stored locally' do
              let(:download_headers) do
                { 'Content-Transfer-Encoding' => 'binary',
                  'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
              end

              before do
                download_artifact
              end

              it 'download artifacts' do
                expect(response).to have_http_status(200)
                expect(response.headers).to include download_headers
              end
            end

            context 'when artifacts are stored remotely' do
              let(:store) { JobArtifactUploader::Store::REMOTE }
              let!(:job) { create(:ci_build) }

              context 'when proxy download is being used' do
                before do
                  download_artifact(direct_download: false)
                end

                it 'uses workhorse send-url' do
                  expect(response).to have_gitlab_http_status(200)
                  expect(response.headers).to include(
                    'Gitlab-Workhorse-Send-Data' => /send-url:/)
                end
              end

              context 'when direct download is being used' do
                before do
                  download_artifact(direct_download: true)
                end

                it 'receive redirect for downloading artifacts' do
                  expect(response).to have_gitlab_http_status(302)
                  expect(response.headers).to include('Location')
                end
              end
            end
          end

          context 'when using runnners token' do
            let(:token) { job.project.runners_token }

            before do
              download_artifact
            end

            it 'responds with forbidden' do
              expect(response).to have_gitlab_http_status(403)
            end
          end
        end

        context 'when job does not has artifacts' do
          it 'responds with not found' do
            download_artifact

            expect(response).to have_gitlab_http_status(404)
          end
        end

        def download_artifact(params = {}, request_headers = headers)
          params = params.merge(token: token)
          job.reload

          get api("/jobs/#{job.id}/artifacts"), params, request_headers
        end
      end
    end
  end
end
