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
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
    let(:runner) { create(:ci_runner, :project, projects: [project]) }
    let(:user) { create(:user) }
    let(:job) do
      create(:ci_build, :artifacts, :extended_options,
             pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0)
    end

    describe 'artifacts' do
      let(:job) { create(:ci_build, :pending, user: user, project: project, pipeline: pipeline, runner_id: runner.id) }
      let(:jwt) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
      let(:headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => jwt } }
      let(:headers_with_token) { headers.merge(API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.token) }
      let(:file_upload) { fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }
      let(:file_upload2) { fixture_file_upload('spec/fixtures/dk.png', 'image/gif') }

      before do
        stub_artifacts_object_storage
        job.run!
      end

      shared_examples_for 'rejecting artifacts that are too large' do
        let(:filesize) { 100.megabytes.to_i }
        let(:sample_max_size) { (filesize / 1.megabyte) - 10 } # Set max size to be smaller than file size to trigger error

        shared_examples_for 'failed request' do
          it 'responds with payload too large error' do
            send_request

            expect(response).to have_gitlab_http_status(:payload_too_large)
          end
        end

        context 'based on plan limit setting' do
          let(:application_max_size) { sample_max_size + 100 }
          let(:limit_name) { "#{Ci::JobArtifact::PLAN_LIMIT_PREFIX}archive" }

          before do
            create(:plan_limits, :default_plan, limit_name => sample_max_size)
            stub_application_setting(max_artifacts_size: application_max_size)
          end

          it_behaves_like 'failed request'
        end

        context 'based on application setting' do
          before do
            stub_application_setting(max_artifacts_size: sample_max_size)
          end

          it_behaves_like 'failed request'
        end

        context 'based on root namespace setting' do
          let(:application_max_size) { sample_max_size + 10 }

          before do
            stub_application_setting(max_artifacts_size: application_max_size)
            parent_group.update!(max_artifacts_size: sample_max_size)
          end

          it_behaves_like 'failed request'
        end

        context 'based on child namespace setting' do
          let(:application_max_size) { sample_max_size + 10 }
          let(:root_namespace_max_size) { sample_max_size + 10 }

          before do
            stub_application_setting(max_artifacts_size: application_max_size)
            parent_group.update!(max_artifacts_size: root_namespace_max_size)
            group.update!(max_artifacts_size: sample_max_size)
          end

          it_behaves_like 'failed request'
        end

        context 'based on project setting' do
          let(:application_max_size) { sample_max_size + 10 }
          let(:root_namespace_max_size) { sample_max_size + 10 }
          let(:child_namespace_max_size) { sample_max_size + 10 }

          before do
            stub_application_setting(max_artifacts_size: application_max_size)
            parent_group.update!(max_artifacts_size: root_namespace_max_size)
            group.update!(max_artifacts_size: child_namespace_max_size)
            project.update!(max_artifacts_size: sample_max_size)
          end

          it_behaves_like 'failed request'
        end
      end

      describe 'POST /api/v4/jobs/:id/artifacts/authorize' do
        context 'when using token as parameter' do
          context 'and the artifact is too large' do
            it_behaves_like 'rejecting artifacts that are too large' do
              let(:success_code) { :ok }
              let(:send_request) { authorize_artifacts_with_token_in_params(filesize: filesize) }
            end
          end

          context 'posting artifacts to running job' do
            subject do
              authorize_artifacts_with_token_in_params
            end

            it_behaves_like 'API::CI::Runner application context metadata', 'POST /api/:version/jobs/:id/artifacts/authorize' do
              let(:send_request) { subject }
            end

            it 'updates runner info' do
              expect { subject }.to change { runner.reload.contacted_at }
            end

            shared_examples 'authorizes local file' do
              it 'succeeds' do
                subject

                expect(response).to have_gitlab_http_status(:ok)
                expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                expect(json_response['TempPath']).to eq(JobArtifactUploader.workhorse_local_upload_path)
                expect(json_response['RemoteObject']).to be_nil
                expect(json_response['MaximumSize']).not_to be_nil
              end
            end

            context 'when using local storage' do
              it_behaves_like 'authorizes local file'
            end

            context 'when using remote storage' do
              context 'when direct upload is enabled' do
                before do
                  stub_artifacts_object_storage(enabled: true, direct_upload: true)
                end

                it 'succeeds' do
                  subject

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                  expect(json_response).not_to have_key('TempPath')
                  expect(json_response['RemoteObject']).to have_key('ID')
                  expect(json_response['RemoteObject']).to have_key('GetURL')
                  expect(json_response['RemoteObject']).to have_key('StoreURL')
                  expect(json_response['RemoteObject']).to have_key('DeleteURL')
                  expect(json_response['RemoteObject']).to have_key('MultipartUpload')
                  expect(json_response['MaximumSize']).not_to be_nil
                end
              end

              context 'when direct upload is disabled' do
                before do
                  stub_artifacts_object_storage(enabled: true, direct_upload: false)
                end

                it_behaves_like 'authorizes local file'
              end
            end

            context 'when job does not exist anymore' do
              before do
                allow(job).to receive(:id).and_return(non_existing_record_id)
              end

              it 'returns 403 Forbidden' do
                subject

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end
        end

        context 'when using token as header' do
          it 'authorizes posting artifacts to running job' do
            authorize_artifacts_with_token_in_headers

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            expect(json_response['TempPath']).not_to be_nil
            expect(json_response['MaximumSize']).not_to be_nil
          end

          it 'fails to post too large artifact' do
            stub_application_setting(max_artifacts_size: 0)

            authorize_artifacts_with_token_in_headers(filesize: 100)

            expect(response).to have_gitlab_http_status(:payload_too_large)
          end
        end

        context 'when using runners token' do
          it 'fails to authorize artifacts posting' do
            authorize_artifacts(token: job.project.runners_token)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        it 'reject requests that did not go through gitlab-workhorse' do
          headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

          authorize_artifacts

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'authorization token is invalid' do
          it 'responds with forbidden' do
            authorize_artifacts(token: 'invalid', filesize: 100 )

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'authorize uploading of an lsif artifact' do
          it 'adds ProcessLsif header' do
            authorize_artifacts_with_token_in_headers(artifact_type: :lsif)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['ProcessLsif']).to be_truthy
          end

          it 'tracks code_intelligence usage ping' do
            tracking_params = {
              event_names: 'i_source_code_code_intelligence',
              start_date: Date.yesterday,
              end_date: Date.today
            }

            expect { authorize_artifacts_with_token_in_headers(artifact_type: :lsif) }
              .to change { Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**tracking_params) }
              .by(1)
          end
        end

        def authorize_artifacts(params = {}, request_headers = headers)
          post api("/jobs/#{job.id}/artifacts/authorize"), params: params, headers: request_headers
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
        it_behaves_like 'API::CI::Runner application context metadata', 'POST /api/:version/jobs/:id/artifacts' do
          let(:send_request) do
            upload_artifacts(file_upload, headers_with_token)
          end
        end

        it 'updates runner info' do
          expect { upload_artifacts(file_upload, headers_with_token) }.to change { runner.reload.contacted_at }
        end

        context 'when the artifact is too large' do
          it_behaves_like 'rejecting artifacts that are too large' do
            # This filesize validation also happens in non remote stored files,
            # it's just that it's hard to stub the filesize in other cases to be
            # more than a megabyte.
            let!(:fog_connection) do
              stub_artifacts_object_storage(direct_upload: true)
            end

            let(:file_upload) { fog_to_uploaded_file(object) }
            let(:success_code) { :created }

            let(:object) do
              fog_connection.directories.new(key: 'artifacts').files.create( # rubocop:disable Rails/SaveBang
                key: 'tmp/uploads/12312300',
                body: 'content'
              )
            end

            let(:send_request) do
              upload_artifacts(file_upload, headers_with_token, 'file.remote_id' => '12312300')
            end

            before do
              allow(object).to receive(:content_length).and_return(filesize)
            end
          end
        end

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

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end

          context 'when job does not exist anymore' do
            before do
              allow(job).to receive(:id).and_return(non_existing_record_id)
            end

            it 'returns 403 Forbidden' do
              upload_artifacts(file_upload, headers_with_token)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end

          context 'when job is running' do
            shared_examples 'successful artifacts upload' do
              it 'updates successfully' do
                expect(response).to have_gitlab_http_status(:created)
              end
            end

            context 'when uses accelerated file post' do
              context 'for file stored locally' do
                before do
                  upload_artifacts(file_upload, headers_with_token)
                end

                it_behaves_like 'successful artifacts upload'
              end

              context 'for file stored remotely' do
                let!(:fog_connection) do
                  stub_artifacts_object_storage(direct_upload: true)
                end

                let(:object) do
                  fog_connection.directories.new(key: 'artifacts').files.create( # rubocop:disable Rails/SaveBang
                    key: 'tmp/uploads/12312300',
                    body: 'content'
                  )
                end

                let(:file_upload) { fog_to_uploaded_file(object) }

                before do
                  upload_artifacts(file_upload, headers_with_token, 'file.remote_id' => remote_id)
                end

                context 'when valid remote_id is used' do
                  let(:remote_id) { '12312300' }

                  it_behaves_like 'successful artifacts upload'
                end

                context 'when invalid remote_id is used' do
                  let(:remote_id) { 'invalid id' }

                  it 'responds with bad request' do
                    expect(response).to have_gitlab_http_status(:internal_server_error)
                    expect(json_response['message']).to eq("Missing file")
                  end
                end
              end
            end

            context 'when using runners token' do
              it 'responds with forbidden' do
                upload_artifacts(file_upload, headers.merge(API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.project.runners_token))

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context 'when artifacts post request does not contain file' do
            it 'fails to post artifacts without file' do
              post api("/jobs/#{job.id}/artifacts"), params: {}, headers: headers_with_token

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'GitLab Workhorse is not configured' do
            it 'fails to post artifacts without GitLab-Workhorse' do
              post api("/jobs/#{job.id}/artifacts"), params: { token: job.token }, headers: {}

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'Is missing GitLab Workhorse token headers' do
            let(:jwt) { JWT.encode({ 'iss' => 'invalid-header' }, Gitlab::Workhorse.secret, 'HS256') }

            it 'fails to post artifacts without GitLab-Workhorse' do
              expect(Gitlab::ErrorTracking).to receive(:track_exception).once

              upload_artifacts(file_upload, headers_with_token)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end

          context 'when setting an expire date' do
            let(:default_artifacts_expire_in) {}
            let(:post_data) do
              { file: file_upload,
                expire_in: expire_in }
            end

            before do
              stub_application_setting(default_artifacts_expire_in: default_artifacts_expire_in)

              upload_artifacts(file_upload, headers_with_token, post_data)
            end

            context 'when an expire_in is given' do
              let(:expire_in) { '7 days' }

              it 'updates when specified' do
                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.artifacts_expire_at).to be_within(5.minutes).of(7.days.from_now)
              end
            end

            context 'when no expire_in is given' do
              let(:expire_in) { nil }

              it 'ignores if not specified' do
                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.artifacts_expire_at).to be_nil
              end

              context 'with application default' do
                context 'when default is 5 days' do
                  let(:default_artifacts_expire_in) { '5 days' }

                  it 'sets to application default' do
                    expect(response).to have_gitlab_http_status(:created)
                    expect(job.reload.artifacts_expire_at).to be_within(5.minutes).of(5.days.from_now)
                  end
                end

                context 'when default is 0' do
                  let(:default_artifacts_expire_in) { '0' }

                  it 'does not set expire_in' do
                    expect(response).to have_gitlab_http_status(:created)
                    expect(job.reload.artifacts_expire_at).to be_nil
                  end
                end

                context 'when value is never' do
                  let(:expire_in) { 'never' }
                  let(:default_artifacts_expire_in) { '5 days' }

                  it 'does not set expire_in' do
                    expect(response).to have_gitlab_http_status(:created)
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
            let!(:metadata_sha256) { Digest::SHA256.file(metadata.path).hexdigest }

            let(:stored_artifacts_file) { job.reload.artifacts_file }
            let(:stored_metadata_file) { job.reload.artifacts_metadata }
            let(:stored_artifacts_size) { job.reload.artifacts_size }
            let(:stored_artifacts_sha256) { job.reload.job_artifacts_archive.file_sha256 }
            let(:stored_metadata_sha256) { job.reload.job_artifacts_metadata.file_sha256 }
            let(:file_keys) { post_data.keys }
            let(:send_rewritten_field) { true }

            before do
              workhorse_finalize_with_multiple_files(
                api("/jobs/#{job.id}/artifacts"),
                method: :post,
                file_keys: file_keys,
                params: post_data,
                headers: headers_with_token,
                send_rewritten_field: send_rewritten_field
              )
            end

            context 'when posts data accelerated by workhorse is correct' do
              let(:post_data) { { file: artifacts, metadata: metadata } }

              it 'stores artifacts and artifacts metadata' do
                expect(response).to have_gitlab_http_status(:created)
                expect(stored_artifacts_file.filename).to eq(artifacts.original_filename)
                expect(stored_metadata_file.filename).to eq(metadata.original_filename)
                expect(stored_artifacts_size).to eq(artifacts.size)
                expect(stored_artifacts_sha256).to eq(artifacts_sha256)
                expect(stored_metadata_sha256).to eq(metadata_sha256)
              end
            end

            context 'with a malicious file.path param' do
              let(:post_data) { {} }
              let(:tmp_file) { Tempfile.new('crafted.file.path') }
              let(:url) { "/jobs/#{job.id}/artifacts?file.path=#{tmp_file.path}" }

              it 'rejects the request' do
                expect(response).to have_gitlab_http_status(:bad_request)
                expect(stored_artifacts_size).to be_nil
              end
            end

            context 'when workhorse header is missing' do
              let(:post_data) { { file: artifacts, metadata: metadata } }
              let(:send_rewritten_field) { false }

              it 'rejects the request' do
                expect(response).to have_gitlab_http_status(:bad_request)
                expect(stored_artifacts_size).to be_nil
              end
            end

            context 'when there is no artifacts file in post data' do
              let(:post_data) do
                { metadata: metadata }
              end

              it 'is expected to respond with bad request' do
                expect(response).to have_gitlab_http_status(:bad_request)
              end

              it 'does not store metadata' do
                expect(stored_metadata_file).to be_nil
              end
            end
          end

          context 'when artifact_type is archive' do
            context 'when artifact_format is zip' do
              let(:params) { { artifact_type: :archive, artifact_format: :zip } }

              it 'stores junit test report' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.job_artifacts_archive).not_to be_nil
              end
            end

            context 'when artifact_format is gzip' do
              let(:params) { { artifact_type: :archive, artifact_format: :gzip } }

              it 'returns an error' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(job.reload.job_artifacts_archive).to be_nil
              end
            end
          end

          context 'when artifact_type is junit' do
            context 'when artifact_format is gzip' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/junit/junit.xml.gz') }
              let(:params) { { artifact_type: :junit, artifact_format: :gzip } }

              it 'stores junit test report' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.job_artifacts_junit).not_to be_nil
              end
            end

            context 'when artifact_format is raw' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/junit/junit.xml.gz') }
              let(:params) { { artifact_type: :junit, artifact_format: :raw } }

              it 'returns an error' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(job.reload.job_artifacts_junit).to be_nil
              end
            end
          end

          context 'when artifact_type is metrics_referee' do
            context 'when artifact_format is gzip' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/referees/metrics_referee.json.gz') }
              let(:params) { { artifact_type: :metrics_referee, artifact_format: :gzip } }

              it 'stores metrics_referee data' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.job_artifacts_metrics_referee).not_to be_nil
              end
            end

            context 'when artifact_format is raw' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/referees/metrics_referee.json.gz') }
              let(:params) { { artifact_type: :metrics_referee, artifact_format: :raw } }

              it 'returns an error' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(job.reload.job_artifacts_metrics_referee).to be_nil
              end
            end
          end

          context 'when artifact_type is network_referee' do
            context 'when artifact_format is gzip' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/referees/network_referee.json.gz') }
              let(:params) { { artifact_type: :network_referee, artifact_format: :gzip } }

              it 'stores network_referee data' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.job_artifacts_network_referee).not_to be_nil
              end
            end

            context 'when artifact_format is raw' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/referees/network_referee.json.gz') }
              let(:params) { { artifact_type: :network_referee, artifact_format: :raw } }

              it 'returns an error' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(job.reload.job_artifacts_network_referee).to be_nil
              end
            end
          end

          context 'when artifact_type is dotenv' do
            context 'when artifact_format is gzip' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/build.env.gz') }
              let(:params) { { artifact_type: :dotenv, artifact_format: :gzip } }

              it 'stores dotenv file' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:created)
                expect(job.reload.job_artifacts_dotenv).not_to be_nil
              end

              it 'parses dotenv file' do
                expect do
                  upload_artifacts(file_upload, headers_with_token, params)
                end.to change { job.job_variables.count }.from(0).to(2)
              end

              context 'when parse error happens' do
                let(:file_upload) { fixture_file_upload('spec/fixtures/ci_build_artifacts_metadata.gz') }

                it 'returns an error' do
                  upload_artifacts(file_upload, headers_with_token, params)

                  expect(response).to have_gitlab_http_status(:bad_request)
                  expect(json_response['message']).to eq('Invalid Format')
                end
              end
            end

            context 'when artifact_format is raw' do
              let(:file_upload) { fixture_file_upload('spec/fixtures/build.env.gz') }
              let(:params) { { artifact_type: :dotenv, artifact_format: :raw } }

              it 'returns an error' do
                upload_artifacts(file_upload, headers_with_token, params)

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(job.reload.job_artifacts_dotenv).to be_nil
              end
            end
          end
        end

        context 'when artifacts already exist for the job' do
          let(:params) do
            {
              artifact_type: :archive,
              artifact_format: :zip,
              'file.sha256' => uploaded_sha256
            }
          end

          let(:existing_sha256) { '0' * 64 }

          let!(:existing_artifact) do
            create(:ci_job_artifact, :archive, file_sha256: existing_sha256, job: job)
          end

          context 'when sha256 is the same of the existing artifact' do
            let(:uploaded_sha256) { existing_sha256 }

            it 'ignores the new artifact' do
              upload_artifacts(file_upload, headers_with_token, params)

              expect(response).to have_gitlab_http_status(:created)
              expect(job.reload.job_artifacts_archive).to eq(existing_artifact)
            end
          end

          context 'when sha256 is different than the existing artifact' do
            let(:uploaded_sha256) { '1' * 64 }

            it 'logs and returns an error' do
              expect(Gitlab::ErrorTracking).to receive(:track_exception)

              upload_artifacts(file_upload, headers_with_token, params)

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(job.reload.job_artifacts_archive).to eq(existing_artifact)
            end
          end
        end

        context 'when object storage throws errors' do
          let(:params) { { artifact_type: :archive, artifact_format: :zip } }

          it 'does not store artifacts' do
            allow_next_instance_of(JobArtifactUploader) do |uploader|
              allow(uploader).to receive(:store!).and_raise(Errno::EIO)
            end

            upload_artifacts(file_upload, headers_with_token, params)

            expect(response).to have_gitlab_http_status(:service_unavailable)
            expect(job.reload.job_artifacts_archive).to be_nil
          end
        end

        context 'when artifacts are being stored outside of tmp path' do
          let(:new_tmpdir) { Dir.mktmpdir }

          before do
            # init before overwriting tmp dir
            file_upload

            # by configuring this path we allow to pass file from @tmpdir only
            # but all temporary files are stored in system tmp directory
            allow(Dir).to receive(:tmpdir).and_return(new_tmpdir)
          end

          after do
            FileUtils.remove_entry(new_tmpdir)
          end

          it 'fails to post artifacts for outside of tmp path' do
            upload_artifacts(file_upload, headers_with_token)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        def upload_artifacts(file, headers = {}, params = {})
          workhorse_finalize(
            api("/jobs/#{job.id}/artifacts"),
            method: :post,
            file_key: :file,
            params: params.merge(file: file),
            headers: headers,
            send_rewritten_field: true
          )
        end
      end

      describe 'GET /api/v4/jobs/:id/artifacts' do
        let(:token) { job.token }

        it_behaves_like 'API::CI::Runner application context metadata', 'GET /api/:version/jobs/:id/artifacts' do
          let(:send_request) { download_artifact }
        end

        it 'updates runner info' do
          expect { download_artifact }.to change { runner.reload.contacted_at }
        end

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
                  'Content-Disposition' => %q(attachment; filename="ci_build_artifacts.zip"; filename*=UTF-8''ci_build_artifacts.zip) }
              end

              before do
                download_artifact
              end

              it 'download artifacts' do
                expect(response).to have_gitlab_http_status(:ok)
                expect(response.headers.to_h).to include download_headers
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
                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response.headers.to_h).to include(
                    'Gitlab-Workhorse-Send-Data' => /send-url:/)
                end
              end

              context 'when direct download is being used' do
                before do
                  download_artifact(direct_download: true)
                end

                it 'receive redirect for downloading artifacts' do
                  expect(response).to have_gitlab_http_status(:found)
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
              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end

        context 'when job does not have artifacts' do
          it 'responds with not found' do
            download_artifact

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when job does not exist anymore' do
          before do
            allow(job).to receive(:id).and_return(non_existing_record_id)
          end

          it 'responds with 403 Forbidden' do
            get api("/jobs/#{job.id}/artifacts"), params: { token: token }, headers: headers

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        def download_artifact(params = {}, request_headers = headers)
          params = params.merge(token: token)
          job.reload

          get api("/jobs/#{job.id}/artifacts"), params: params, headers: request_headers
        end
      end
    end
  end
end
