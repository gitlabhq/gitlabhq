# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
    allow_any_instance_of(::Ci::Runner).to receive(:cache_attributes)
  end

  describe '/api/v4/jobs' do
    let(:group) { create(:group, :nested) }
    let(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
    let(:runner) { create(:ci_runner, :project, projects: [project]) }
    let(:user) { create(:user) }
    let(:job) do
      create(:ci_build, :pending, :queued, :artifacts, :extended_options,
             pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0)
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
              expect(response).to have_gitlab_http_status(:no_content)
              expect(response.header).to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when last_update is up-to-date' do
            let(:last_update) { runner.ensure_runner_queue_value }

            it 'gives 204 and set the same X-GitLab-Last-Update' do
              expect(response).to have_gitlab_http_status(:no_content)
              expect(response.header['X-GitLab-Last-Update']).to eq(last_update)
            end
          end

          context 'when last_update is outdated' do
            let(:last_update) { runner.ensure_runner_queue_value }
            let(:new_update) { runner.tick_runner_queue }

            it 'gives 204 and set a new X-GitLab-Last-Update' do
              expect(response).to have_gitlab_http_status(:no_content)
              expect(response.header['X-GitLab-Last-Update']).to eq(new_update)
            end
          end

          context 'when beta version is sent' do
            let(:user_agent) { 'gitlab-runner 9.0.0~beta.167.g2b2bacc (master; go1.7.4; linux/amd64)' }

            it { expect(response).to have_gitlab_http_status(:no_content) }
          end

          context 'when pre-9-0 version is sent' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0 (1-6-stable; go1.6.3; linux/amd64)' }

            it { expect(response).to have_gitlab_http_status(:no_content) }
          end

          context 'when pre-9-0 beta version is sent' do
            let(:user_agent) { 'gitlab-ci-multi-runner 1.6.0~beta.167.g2b2bacc (master; go1.6.3; linux/amd64)' }

            it { expect(response).to have_gitlab_http_status(:no_content) }
          end
        end
      end

      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/jobs/request')

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/jobs/request'), params: { token: 'invalid' }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when valid token is provided' do
        context 'when Runner is not active' do
          let(:runner) { create(:ci_runner, :inactive) }
          let(:update_value) { runner.ensure_runner_queue_value }

          it 'returns 204 error' do
            request_job

            expect(response).to have_gitlab_http_status(:no_content)
            expect(response.header['X-GitLab-Last-Update']).to eq(update_value)
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
            create(:ci_build, :pending, :queued)
          end

          it_behaves_like 'no jobs available'
        end

        context 'when shared runner requests job for project without shared_runners_enabled' do
          let(:runner) { create(:ci_runner, :instance) }

          it_behaves_like 'no jobs available'
        end

        context 'when there is a pending job' do
          let(:expected_job_info) do
            { 'id' => job.id,
              'name' => job.name,
              'stage' => job.stage,
              'project_id' => job.project.id,
              'project_name' => job.project.name }
          end

          let(:expected_git_info) do
            { 'repo_url' => job.repo_url,
              'ref' => job.ref,
              'sha' => job.sha,
              'before_sha' => job.before_sha,
              'ref_type' => 'branch',
              'refspecs' => ["+#{pipeline.sha}:refs/pipelines/#{pipeline.id}",
                             "+refs/heads/#{job.ref}:refs/remotes/origin/#{job.ref}"],
              'depth' => project.ci_default_git_depth }
          end

          let(:expected_steps) do
            [{ 'name' => 'script',
               'script' => %w(echo),
               'timeout' => job.metadata_timeout,
               'when' => 'on_success',
               'allow_failure' => false },
             { 'name' => 'after_script',
               'script' => %w(ls date),
               'timeout' => job.metadata_timeout,
               'when' => 'always',
               'allow_failure' => true }]
          end

          let(:expected_variables) do
            [{ 'key' => 'CI_JOB_NAME', 'value' => 'spinach', 'public' => true, 'masked' => false },
             { 'key' => 'CI_JOB_STAGE', 'value' => 'test', 'public' => true, 'masked' => false },
             { 'key' => 'DB_NAME', 'value' => 'postgres', 'public' => true, 'masked' => false }]
          end

          let(:expected_artifacts) do
            [{ 'name' => 'artifacts_file',
               'untracked' => false,
               'paths' => %w(out/),
               'when' => 'always',
               'expire_in' => '7d',
               "artifact_type" => "archive",
               "artifact_format" => "zip" }]
          end

          let(:expected_cache) do
            [{ 'key' => 'cache_key',
               'untracked' => false,
               'paths' => ['vendor/*'],
               'policy' => 'pull-push',
               'when' => 'on_success' }]
          end

          let(:expected_features) do
            {
              'trace_sections' => true,
              'failure_reasons' => include('script_failure')
            }
          end

          it 'picks a job' do
            request_job info: { platform: :darwin }

            expect(response).to have_gitlab_http_status(:created)
            expect(response.headers['Content-Type']).to eq('application/json')
            expect(response.headers).not_to have_key('X-GitLab-Last-Update')
            expect(runner.reload.platform).to eq('darwin')
            expect(json_response['id']).to eq(job.id)
            expect(json_response['token']).to eq(job.token)
            expect(json_response['job_info']).to eq(expected_job_info)
            expect(json_response['git_info']).to eq(expected_git_info)
            expect(json_response['image']).to eq({ 'name' => 'ruby:2.7', 'entrypoint' => '/bin/sh', 'ports' => [] })
            expect(json_response['services']).to eq([{ 'name' => 'postgres', 'entrypoint' => nil,
                                                       'alias' => nil, 'command' => nil, 'ports' => [] },
                                                     { 'name' => 'docker:stable-dind', 'entrypoint' => '/bin/sh',
                                                       'alias' => 'docker', 'command' => 'sleep 30', 'ports' => [] }])
            expect(json_response['steps']).to eq(expected_steps)
            expect(json_response['artifacts']).to eq(expected_artifacts)
            expect(json_response['cache']).to eq(expected_cache)
            expect(json_response['variables']).to include(*expected_variables)
            expect(json_response['features']).to match(expected_features)
          end

          it 'creates persistent ref' do
            expect_any_instance_of(::Ci::PersistentRef).to receive(:create_ref)
              .with(job.sha, "refs/#{Repository::REF_PIPELINES}/#{job.commit_id}")

            request_job info: { platform: :darwin }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['id']).to eq(job.id)
          end

          context 'when job is made for tag' do
            let!(:job) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }

            it 'sets branch as ref_type' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['git_info']['ref_type']).to eq('tag')
            end

            context 'when GIT_DEPTH is specified' do
              before do
                create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 1, pipeline: pipeline)
              end

              it 'specifies refspecs' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['git_info']['refspecs']).to include("+refs/tags/#{job.ref}:refs/tags/#{job.ref}")
              end
            end

            context 'when a Gitaly exception is thrown during response' do
              before do
                allow_next_instance_of(Ci::BuildRunnerPresenter) do |instance|
                  allow(instance).to receive(:artifacts).and_raise(GRPC::DeadlineExceeded)
                end
              end

              it 'fails the job as a scheduler failure' do
                request_job

                expect(response).to have_gitlab_http_status(:no_content)
                expect(job.reload.failed?).to be_truthy
                expect(job.failure_reason).to eq('scheduler_failure')
                expect(job.runner_id).to eq(runner.id)
                expect(job.runner_session).to be_nil
              end
            end

            context 'when GIT_DEPTH is not specified and there is no default git depth for the project' do
              before do
                project.update!(ci_default_git_depth: nil)
              end

              it 'specifies refspecs' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['git_info']['refspecs'])
                  .to contain_exactly("+#{pipeline.sha}:refs/pipelines/#{pipeline.id}",
                                      '+refs/tags/*:refs/tags/*',
                                      '+refs/heads/*:refs/remotes/origin/*')
              end
            end
          end

          context 'when job filtered by job_age' do
            let!(:job) do
              create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0, queued_at: 60.seconds.ago)
            end

            before do
              job.queuing_entry&.update!(created_at: 60.seconds.ago)
            end

            context 'job is queued less than job_age parameter' do
              let(:job_age) { 120 }

              it 'gives 204' do
                request_job(job_age: job_age)

                expect(response).to have_gitlab_http_status(:no_content)
              end
            end

            context 'job is queued more than job_age parameter' do
              let(:job_age) { 30 }

              it 'picks a job' do
                request_job(job_age: job_age)

                expect(response).to have_gitlab_http_status(:created)
              end
            end
          end

          context 'when job is made for branch' do
            it 'sets tag as ref_type' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['git_info']['ref_type']).to eq('branch')
            end

            context 'when GIT_DEPTH is specified' do
              before do
                create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 1, pipeline: pipeline)
              end

              it 'specifies refspecs' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['git_info']['refspecs']).to include("+refs/heads/#{job.ref}:refs/remotes/origin/#{job.ref}")
              end
            end

            context 'when GIT_DEPTH is not specified and there is no default git depth for the project' do
              before do
                project.update!(ci_default_git_depth: nil)
              end

              it 'specifies refspecs' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['git_info']['refspecs'])
                  .to contain_exactly("+#{pipeline.sha}:refs/pipelines/#{pipeline.id}",
                                      '+refs/tags/*:refs/tags/*',
                                      '+refs/heads/*:refs/remotes/origin/*')
              end
            end
          end

          context 'when job is for a release' do
            let!(:job) { create(:ci_build, :pending, :queued, :release_options, pipeline: pipeline) }

            context 'when `multi_build_steps` is passed by the runner' do
              it 'exposes release info' do
                request_job info: { features: { multi_build_steps: true } }

                expect(response).to have_gitlab_http_status(:created)
                expect(response.headers).not_to have_key('X-GitLab-Last-Update')
                expect(json_response['steps']).to eq([
                  {
                    "name" => "script",
                    "script" => ["make changelog | tee release_changelog.txt"],
                    "timeout" => 3600,
                    "when" => "on_success",
                    "allow_failure" => false
                  },
                  {
                    "name" => "release",
                    "script" =>
                    ["release-cli create --name \"Release $CI_COMMIT_SHA\" --description \"Created using the release-cli $EXTRA_DESCRIPTION\" --tag-name \"release-$CI_COMMIT_SHA\" --ref \"$CI_COMMIT_SHA\" --assets-link \"{\\\"url\\\":\\\"https://example.com/assets/1\\\",\\\"name\\\":\\\"asset1\\\"}\""],
                    "timeout" => 3600,
                    "when" => "on_success",
                    "allow_failure" => false
                  }
                ])
              end
            end

            context 'when `multi_build_steps` is not passed by the runner' do
              it 'drops the job' do
                request_job

                expect(response).to have_gitlab_http_status(:no_content)
              end
            end
          end

          context 'when job is made for merge request' do
            let(:pipeline) { create(:ci_pipeline, source: :merge_request_event, project: project, ref: 'feature', merge_request: merge_request) }
            let!(:job) { create(:ci_build, :pending, :queued, pipeline: pipeline, name: 'spinach', ref: 'feature', stage: 'test', stage_idx: 0) }
            let(:merge_request) { create(:merge_request) }

            it 'sets branch as ref_type' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['git_info']['ref_type']).to eq('branch')
            end

            context 'when GIT_DEPTH is specified' do
              before do
                create(:ci_pipeline_variable, key: 'GIT_DEPTH', value: 1, pipeline: pipeline)
              end

              it 'returns the overwritten git depth for merge request refspecs' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['git_info']['depth']).to eq(1)
              end
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

                expect(response).to have_gitlab_http_status(:created)
                expect(runner.reload.read_attribute(param.to_sym)).to eq(value)
              end
            end
          end

          it "sets the runner's config" do
            request_job info: { 'config' => { 'gpus' => 'all', 'ignored' => 'hello' } }

            expect(response).to have_gitlab_http_status(:created)
            expect(runner.reload.config).to eq( { 'gpus' => 'all' } )
          end

          it "sets the runner's ip_address" do
            post api('/jobs/request'),
              params: { token: runner.token },
              headers: { 'User-Agent' => user_agent, 'X-Forwarded-For' => '123.222.123.222' }

            expect(response).to have_gitlab_http_status(:created)
            expect(runner.reload.ip_address).to eq('123.222.123.222')
          end

          it "handles multiple X-Forwarded-For addresses" do
            post api('/jobs/request'),
              params: { token: runner.token },
              headers: { 'User-Agent' => user_agent, 'X-Forwarded-For' => '123.222.123.222, 127.0.0.1' }

            expect(response).to have_gitlab_http_status(:created)
            expect(runner.reload.ip_address).to eq('123.222.123.222')
          end

          context 'when concurrently updating a job' do
            before do
              expect_any_instance_of(::Ci::Build).to receive(:run!)
                  .and_raise(ActiveRecord::StaleObjectError.new(nil, nil))
            end

            it 'returns a conflict' do
              request_job

              expect(response).to have_gitlab_http_status(:conflict)
              expect(response.headers).not_to have_key('X-GitLab-Last-Update')
            end
          end

          context 'when project and pipeline have multiple jobs' do
            let!(:job) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:job2) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'rubocop', stage: 'test', stage_idx: 0) }
            let!(:test_job) { create(:ci_build, :pending, :queued, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

            before do
              job.success
              job2.success
            end

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(2)
              expect(json_response['dependencies']).to include(
                { 'id' => job.id, 'name' => job.name, 'token' => job.token },
                { 'id' => job2.id, 'name' => job2.name, 'token' => job2.token })
            end

            describe 'preloading job_artifacts_archive' do
              context 'when the feature flag is disabled' do
                before do
                  stub_feature_flags(preload_associations_jobs_request_api_endpoint: false)
                end

                it 'queries the ci_job_artifacts table multiple times' do
                  expect { request_job }.to exceed_all_query_limit(1).for_model(::Ci::JobArtifact)
                end

                it 'queries the ci_builds table more than three times' do
                  expect { request_job }.to exceed_all_query_limit(3).for_model(::Ci::Build)
                end
              end

              context 'when the feature flag is enabled' do
                before do
                  stub_feature_flags(preload_associations_jobs_request_api_endpoint: true)
                end

                it 'queries the ci_job_artifacts table once only' do
                  expect { request_job }.not_to exceed_all_query_limit(1).for_model(::Ci::JobArtifact)
                end

                it 'queries the ci_builds table five times' do
                  expect { request_job }.not_to exceed_all_query_limit(5).for_model(::Ci::Build)
                end
              end
            end
          end

          context 'when pipeline have jobs with artifacts' do
            let!(:job) { create(:ci_build, :pending, :queued, :tag, :artifacts, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:test_job) { create(:ci_build, :pending, :queued, pipeline: pipeline, name: 'deploy', stage: 'deploy', stage_idx: 1) }

            before do
              job.success
            end

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(1)
              expect(json_response['dependencies']).to include(
                { 'id' => job.id, 'name' => job.name, 'token' => job.token,
                  'artifacts_file' => { 'filename' => 'ci_build_artifacts.zip', 'size' => 107464 } })
            end
          end

          context 'when explicit dependencies are defined' do
            let!(:job) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:job2) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'rubocop', stage: 'test', stage_idx: 0) }
            let!(:test_job) do
              create(:ci_build, :pending, :queued, pipeline: pipeline, token: 'test-job-token', name: 'deploy',
                                stage: 'deploy', stage_idx: 1,
                                options: { script: ['bash'], dependencies: [job2.name] })
            end

            before do
              job.success
              job2.success
            end

            it 'returns dependent jobs' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['id']).to eq(test_job.id)
              expect(json_response['dependencies'].count).to eq(1)
              expect(json_response['dependencies'][0]).to include('id' => job2.id, 'name' => job2.name, 'token' => job2.token)
            end
          end

          context 'when dependencies is an empty array' do
            let!(:job) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0) }
            let!(:job2) { create(:ci_build, :pending, :queued, :tag, pipeline: pipeline, name: 'rubocop', stage: 'test', stage_idx: 0) }
            let!(:empty_dependencies_job) do
              create(:ci_build, :pending, :queued, pipeline: pipeline, token: 'test-job-token', name: 'empty_dependencies_job',
                                stage: 'deploy', stage_idx: 1,
                                options: { script: ['bash'], dependencies: [] })
            end

            before do
              job.success
              job2.success
            end

            it 'returns an empty array' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response['id']).to eq(empty_dependencies_job.id)
              expect(json_response['dependencies'].count).to eq(0)
            end
          end

          context 'when job has no tags' do
            before do
              job.update!(tags: [])
            end

            context 'when runner is allowed to pick untagged jobs' do
              before do
                runner.update_column(:run_untagged, true)
              end

              it 'picks job' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
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
              [{ 'key' => 'CI_JOB_NAME', 'value' => 'spinach', 'public' => true, 'masked' => false },
               { 'key' => 'CI_JOB_STAGE', 'value' => 'test', 'public' => true, 'masked' => false },
               { 'key' => 'CI_PIPELINE_TRIGGERED', 'value' => 'true', 'public' => true, 'masked' => false },
               { 'key' => 'DB_NAME', 'value' => 'postgres', 'public' => true, 'masked' => false },
               { 'key' => 'SECRET_KEY', 'value' => 'secret_value', 'public' => false, 'masked' => false },
               { 'key' => 'TRIGGER_KEY_1', 'value' => 'TRIGGER_VALUE_1', 'public' => false, 'masked' => false }]
            end

            let(:trigger) { create(:ci_trigger, project: project) }
            let!(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, builds: [job], trigger: trigger) }

            before do
              project.variables << ::Ci::Variable.new(key: 'SECRET_KEY', value: 'secret_value')
            end

            shared_examples 'expected variables behavior' do
              it 'returns variables for triggers' do
                request_job

                expect(response).to have_gitlab_http_status(:created)
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

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response['runner_info']).to include({ 'timeout' => 1234 })
              end

              context 'when runner specifies lower timeout' do
                let(:runner) { create(:ci_runner, :project, maximum_timeout: 1000, projects: [project]) }

                it 'contains info about timeout overridden by runner' do
                  request_job

                  expect(response).to have_gitlab_http_status(:created)
                  expect(json_response['runner_info']).to include({ 'timeout' => 1000 })
                end
              end

              context 'when runner specifies bigger timeout' do
                let(:runner) { create(:ci_runner, :project, maximum_timeout: 2000, projects: [project]) }

                it 'contains info about timeout not overridden by runner' do
                  request_job

                  expect(response).to have_gitlab_http_status(:created)
                  expect(json_response['runner_info']).to include({ 'timeout' => 1234 })
                end
              end
            end
          end
        end

        describe 'port support' do
          let(:job) { create(:ci_build, :pending, :queued, pipeline: pipeline, options: options) }

          context 'when job image has ports' do
            let(:options) do
              {
                image: {
                  name: 'ruby',
                  ports: [80]
                },
                services: ['mysql']
              }
            end

            it 'returns the image ports' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response).to include(
                'id' => job.id,
                'image' => a_hash_including('name' => 'ruby', 'ports' => [{ 'number' => 80, 'protocol' => 'http', 'name' => 'default_port' }]),
                'services' => all(a_hash_including('name' => 'mysql')))
            end
          end

          context 'when job services settings has ports' do
            let(:options) do
              {
                image: 'ruby',
                services: [
                  {
                    name: 'tomcat',
                    ports: [{ number: 8081, protocol: 'http', name: 'custom_port' }]
                  }
                ]
              }
            end

            it 'returns the service ports' do
              request_job

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response).to include(
                'id' => job.id,
                'image' => a_hash_including('name' => 'ruby'),
                'services' => all(a_hash_including('name' => 'tomcat', 'ports' => [{ 'number' => 8081, 'protocol' => 'http', 'name' => 'custom_port' }])))
            end
          end
        end

        describe 'a job with excluded artifacts' do
          context 'when excluded paths are defined' do
            let(:job) do
              create(:ci_build, :pending, :queued, pipeline: pipeline, token: 'test-job-token', name: 'test',
                                stage: 'deploy', stage_idx: 1,
                                options: { artifacts: { paths: ['abc'], exclude: ['cde'] } })
            end

            context 'when a runner supports this feature' do
              it 'exposes excluded paths' do
                request_job info: { features: { artifacts_exclude: true } }

                expect(response).to have_gitlab_http_status(:created)
                expect(json_response.dig('artifacts').first).to include('exclude' => ['cde'])
              end
            end

            context 'when a runner does not support this feature' do
              it 'does not expose the build at all' do
                request_job

                expect(response).to have_gitlab_http_status(:no_content)
              end
            end
          end

          it 'does not expose excluded paths when these are empty' do
            request_job

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response.dig('artifacts').first).not_to have_key('exclude')
          end
        end

        describe 'setting the application context' do
          subject { request_job }

          context 'when triggered by a user' do
            let(:job) { create(:ci_build, :pending, :queued, user: user, project: project) }

            subject { request_job(id: job.id) }

            it_behaves_like 'storing arguments in the application context' do
              let(:expected_params) { { user: user.username, project: project.full_path, client_id: "user/#{user.id}" } }
            end

            it_behaves_like 'not executing any extra queries for the application context', 3 do
              # Extra queries: User, Project, Route
              let(:subject_proc) { proc { request_job(id: job.id) } }
            end
          end

          context 'when the runner is of project type' do
            it_behaves_like 'storing arguments in the application context' do
              let(:expected_params) { { project: project.full_path, client_id: "runner/#{runner.id}" } }
            end

            it_behaves_like 'not executing any extra queries for the application context', 2 do
              # Extra queries: Project, Route
              let(:subject_proc) { proc { request_job } }
            end
          end

          context 'when the runner is of group type' do
            let(:group) { create(:group) }
            let(:runner) { create(:ci_runner, :group, groups: [group]) }

            it_behaves_like 'storing arguments in the application context' do
              let(:expected_params) { { root_namespace: group.full_path_components.first, client_id: "runner/#{runner.id}" } }
            end

            it_behaves_like 'not executing any extra queries for the application context', 2 do
              # Extra queries: Group, Route
              let(:subject_proc) { proc { request_job } }
            end
          end
        end

        def request_job(token = runner.token, **params)
          new_params = params.merge(token: token, last_update: last_update)
          post api('/jobs/request'), params: new_params.to_json, headers: { 'User-Agent' => user_agent, 'Content-Type': 'application/json' }
        end
      end

      context 'for web-ide job' do
        let_it_be(:user) { create(:user) }
        let_it_be(:project) { create(:project, :repository) }

        let(:runner) { create(:ci_runner, :project, projects: [project]) }
        let(:service) { ::Ci::CreateWebIdeTerminalService.new(project, user, ref: 'master').execute }
        let(:pipeline) { service[:pipeline] }
        let(:build) { pipeline.builds.first }
        let(:job) { {} }
        let(:config_content) do
          'terminal: { image: ruby, services: [mysql], before_script: [ls], tags: [tag-1], variables: { KEY: value } }'
        end

        before do
          stub_webide_config_file(config_content)
          project.add_maintainer(user)

          pipeline
        end

        context 'when runner has matching tag' do
          before do
            runner.update!(tag_list: ['tag-1'])
          end

          it 'successfully picks job' do
            request_job

            build.reload

            expect(build).to be_running
            expect(build.runner).to eq(runner)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to include(
              "id" => build.id,
              "variables" => include("key" => 'KEY', "value" => 'value', "public" => true, "masked" => false),
              "image" => a_hash_including("name" => 'ruby'),
              "services" => all(a_hash_including("name" => 'mysql')),
              "job_info" => a_hash_including("name" => 'terminal', "stage" => 'terminal'))
          end
        end

        context 'when runner does not have matching tags' do
          it 'does not pick a job' do
            request_job

            build.reload

            expect(build).to be_pending
            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        def request_job(token = runner.token, **params)
          post api('/jobs/request'), params: params.merge(token: token)
        end
      end
    end
  end
end
