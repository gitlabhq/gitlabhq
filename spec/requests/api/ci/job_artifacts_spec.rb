# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::JobArtifacts, feature_category: :job_artifacts do
  include HttpBasicAuthHelpers
  include DependencyProxyHelpers
  include Ci::JobTokenScopeHelpers

  include HttpIOHelpers

  let_it_be(:project, reload: true) do
    create(:project, :repository, public_builds: false)
  end

  let_it_be(:other_project, reload: true) do
    create(:project, :repository)
  end

  let_it_be(:pipeline, reload: true) do
    create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
  end

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }

  let!(:job) do
    create(:ci_build, :success, :tags, pipeline: pipeline, artifacts_expire_at: 1.day.since)
  end

  before do
    project.add_developer(user)
  end

  shared_examples 'returns unauthorized' do
    it 'returns unauthorized' do
      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'DELETE /projects/:id/jobs/:job_id/artifacts' do
    let!(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    context 'when project is not undergoing stats refresh' do
      before do
        delete api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        it 'does not delete artifacts' do
          expect(job.job_artifacts.size).to eq 2
        end

        it 'returns status 401 (unauthorized)' do
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'with developer' do
        it 'does not delete artifacts' do
          expect(job.job_artifacts.size).to eq 2
        end

        it 'returns status 403 (forbidden)' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with authorized user' do
        let(:maintainer) { create(:project_member, :maintainer, project: project).user }
        let!(:api_user) { maintainer }

        it 'deletes artifacts' do
          expect(job.job_artifacts.size).to eq 0
        end

        it 'returns status 204 (no content)' do
          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end

    context 'when project is undergoing stats refresh' do
      it_behaves_like 'preventing request because of ongoing project stats refresh' do
        let(:maintainer) { create(:project_member, :maintainer, project: project).user }
        let(:api_user) { maintainer }
        let(:make_request) { delete api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user) }

        it 'does not delete artifacts' do
          make_request

          expect(job.job_artifacts.size).to eq 2
        end
      end
    end
  end

  describe 'DELETE /projects/:id/artifacts' do
    context 'when user is anonymous' do
      let(:api_user) { nil }

      it 'does not execute Ci::JobArtifacts::DeleteProjectArtifactsService' do
        expect(Ci::JobArtifacts::DeleteProjectArtifactsService)
          .not_to receive(:new)

        delete api("/projects/#{project.id}/artifacts", api_user)
      end

      it 'returns status 401 (unauthorized)' do
        delete api("/projects/#{project.id}/artifacts", api_user)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with developer' do
      it 'does not execute Ci::JobArtifacts::DeleteProjectArtifactsService' do
        expect(Ci::JobArtifacts::DeleteProjectArtifactsService)
          .not_to receive(:new)

        delete api("/projects/#{project.id}/artifacts", api_user)
      end

      it 'returns status 403 (forbidden)' do
        delete api("/projects/#{project.id}/artifacts", api_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with authorized user' do
      let(:maintainer) { create(:project_member, :maintainer, project: project).user }
      let!(:api_user) { maintainer }

      it 'executes Ci::JobArtifacts::DeleteProjectArtifactsService' do
        expect_next_instance_of(Ci::JobArtifacts::DeleteProjectArtifactsService, project: project) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        delete api("/projects/#{project.id}/artifacts", api_user)
      end

      it 'returns status 202 (accepted)' do
        delete api("/projects/#{project.id}/artifacts", api_user)

        expect(response).to have_gitlab_http_status(:accepted)
      end

      context 'when project is undergoing stats refresh' do
        let!(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

        it_behaves_like 'preventing request because of ongoing project stats refresh' do
          let(:maintainer) { create(:project_member, :maintainer, project: project).user }
          let(:api_user) { maintainer }
          let(:make_request) { delete api("/projects/#{project.id}/artifacts", api_user) }

          it 'does not delete artifacts' do
            make_request

            expect(job.job_artifacts.size).to eq 2
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts/:artifact_path' do
    context 'when job has artifacts' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

      let(:artifact) do
        'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif'
      end

      it_behaves_like 'enforcing job token policies', :read_jobs do
        before do
          stub_licensed_features(cross_project_pipelines: true)
        end

        around do |example|
          Sidekiq::Testing.inline! { example.run }
        end

        let(:request) do
          get api("/projects/#{source_project.id}/jobs/#{job.id}/artifacts/#{artifact}"),
            params: { job_token: target_job.token }
        end
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          it 'allows to access artifacts' do
            project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when project is public with artifacts that are non public' do
          let(:job) { create(:ci_build, :private_artifacts, :with_private_artifacts_config, pipeline: pipeline) }

          it 'rejects access to artifacts' do
            project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when project is public with builds access disabled' do
          it 'rejects access to artifacts' do
            project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, false)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when project is private' do
          it 'rejects access and hides existence of artifacts' do
            project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is authorized' do
        it 'returns a specific artifact file for a valid path' do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
            .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json', 'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          expect(response.headers.to_h)
            .not_to include('Gitlab-Workhorse-Detect-Content-Type' => 'true')
          expect(response.parsed_body).to be_empty
        end

        context 'when artifacts are locked' do
          it 'allows access to expired artifact' do
            pipeline.artifacts_locked!
            job.update!(artifacts_expire_at: Time.now - 7.days)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'when job does not have artifacts' do
      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_artifact_file(artifact_path)
      get api("/projects/#{project.id}/jobs/#{job.id}/" \
              "artifacts/#{artifact_path}", api_user)
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    shared_examples 'downloads artifact' do
      let(:download_headers) do
        { 'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition' => %q(attachment; filename="ci_build_artifacts.zip"; filename*=UTF-8''ci_build_artifacts.zip) }
      end

      let(:expected_params) { { artifact_size: job.artifacts_file.size } }
      let(:subject_proc) { proc { subject } }

      it 'returns specific job artifacts' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers.to_h).to include(download_headers)
        expect(response.body).to match_file(job.artifacts_file.file.file)
      end

      it_behaves_like 'storing arguments in the application context'
      it_behaves_like 'not executing any extra queries for the application context'
    end

    context 'normal authentication' do
      context 'job with artifacts' do
        context 'when artifacts are stored locally' do
          let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, project: project) }

          subject { get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user) }

          context 'authorized user' do
            it_behaves_like 'downloads artifact'
          end

          context 'when job token is used' do
            let(:other_job) { create(:ci_build, :running, user: user) }

            subject(:request) { get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", job_token: other_job.token) }

            before do
              stub_licensed_features(cross_project_pipelines: true)
            end

            it_behaves_like 'enforcing job token policies', :read_jobs do
              let(:other_job) { target_job }
            end

            context 'when job token scope is enabled' do
              before do
                other_job.project.ci_cd_settings.update!(
                  job_token_scope_enabled: true,
                  inbound_job_token_scope_enabled: true
                )
              end

              it 'does not allow downloading artifacts' do
                subject

                expect(response).to have_gitlab_http_status(:forbidden)
              end

              context 'when project is added to the job token scope' do
                before do
                  make_project_fully_accessible(other_job.project, job.project)
                end

                it_behaves_like 'downloads artifact'

                # https://gitlab.com/gitlab-org/gitlab/-/issues/459908
                it 'logs context data about the job and route' do
                  allow(Gitlab::AppLogger).to receive(:info)

                  expect(::Gitlab::AppLogger).to receive(:info).with a_hash_including({
                    job_id: other_job.id,
                    job_user_id: other_job.user_id,
                    job_project_id: other_job.project_id,
                    'meta.caller_id' => 'GET /api/:version/projects/:id/jobs/:job_id/artifacts'
                  })

                  subject
                end
              end
            end

            it_behaves_like 'logs inbound authorizations via job token', :ok, :forbidden do
              let(:accessed_project) { project }
              let(:origin_project) { other_job.project }

              let(:perform_request) do
                get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", job_token: job_token)
              end
            end
          end

          context 'unauthorized user' do
            let(:api_user) { nil }

            it 'does not return specific job artifacts' do
              subject

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when artifacts are stored remotely' do
          let(:proxy_download) { false }
          let(:job) { create(:ci_build, pipeline: pipeline) }
          let(:fixed_time) { Time.new(2001, 1, 1) }
          let(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job, created_at: fixed_time) }

          before do
            stub_artifacts_object_storage(proxy_download: proxy_download)

            artifact
            job.reload
            travel_to fixed_time

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          context 'when proxy download is enabled' do
            let(:proxy_download) { true }

            it 'responds with the workhorse send-url' do
              expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("send-url:")
            end
          end

          context 'when proxy download is disabled' do
            it 'returns location redirect' do
              expect(response).to have_gitlab_http_status(:found)
            end
          end

          context 'when Google CDN is configured' do
            let(:cdn_config) do
              {
                'provider' => 'Google',
                'url' => 'https://cdn.example.org',
                'key_name' => 'stanhu-key',
                'key' => Base64.urlsafe_encode64(SecureRandom.hex)
              }
            end

            before do
              stub_object_storage_uploader(
                config: Gitlab.config.artifacts.object_store,
                uploader: JobArtifactUploader,
                proxy_download: proxy_download,
                cdn: cdn_config
              )
              allow(Gitlab::ApplicationContext).to receive(:push).and_call_original
            end

            subject { get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user), env: { REMOTE_ADDR: '18.245.0.1' } }

            it 'returns CDN-signed URL' do
              expect(Gitlab::ApplicationContext).to receive(:push).with(artifact_used_cdn: true).and_call_original

              subject

              expect(response.redirect_url).to start_with("https://cdn.example.org/#{artifact.file.path}")
            end
          end

          context 'authorized user' do
            it 'returns the file remote URL', :freeze_time do
              # Signed URLs contain timestamps. Freeze time to avoid flakiness.
              expect(response).to redirect_to(artifact.file.url)
            end
          end

          context 'unauthorized user' do
            let(:api_user) { nil }

            it 'does not return specific job artifacts' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when public project guest and artifacts are non public' do
          let(:api_user) { guest }
          let(:job) { create(:ci_build, :private_artifacts, :with_private_artifacts_config, pipeline: pipeline) }

          before do
            project.update_column(:visibility_level,
              Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)
            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          it 'rejects access and hides existence of artifacts' do
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        it 'does not return job artifacts if not uploaded' do
          get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter }
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    before do
      stub_artifacts_object_storage
      job.success
    end

    def get_for_ref(ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/download", api_user), params: { job: job_name }
    end

    it_behaves_like 'enforcing job token policies', :read_jobs do
      before do
        stub_licensed_features(cross_project_pipelines: true)
      end

      around do |example|
        Sidekiq::Testing.inline! { example.run }
      end

      let(:request) do
        get api("/projects/#{source_project.id}/jobs/artifacts/#{pipeline.ref}/download"),
          params: { job: job.name, job_token: target_job.token }
      end
    end

    context 'when not logged in' do
      let(:api_user) { nil }

      before do
        get_for_ref
      end

      it 'does not find a resource in a private project' do
        expect(project).to be_private
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest }

      before do
        get_for_ref
      end

      it 'gives 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'non-existing job' do
      shared_examples 'not found' do
        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get_for_ref('TAIL')
        end

        it_behaves_like 'not found'
      end

      context 'has no such job' do
        before do
          get_for_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end
    end

    context 'find proper job' do
      let(:job_with_artifacts) { job }

      shared_examples 'a valid file' do
        context 'when artifacts are stored locally', :sidekiq_might_not_need_inline do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' =>
              %(attachment; filename="#{job_with_artifacts.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}) }
          end

          it { expect(response).to have_gitlab_http_status(:ok) }
          it { expect(response.headers.to_h).to include(download_headers) }
        end

        context 'when artifacts are stored remotely' do
          let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
            job.reload

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          it 'returns location redirect' do
            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end

      context 'with regular branch' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'master', sha: project.commit('master').sha)

          get_for_ref('master')
        end

        it_behaves_like 'a valid file'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'improve/awesome', sha: project.commit('improve/awesome').sha)
          get_for_ref('improve/awesome')
        end

        it_behaves_like 'a valid file'
      end

      context 'with job name in a child pipeline' do
        let(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }
        let!(:child_job) { create(:ci_build, :artifacts, :success, name: 'rspec', pipeline: child_pipeline) }
        let(:job_with_artifacts) { child_job }

        before do
          get_for_ref('master', child_job.name)
        end

        it_behaves_like 'a valid file'
      end
    end
  end

  describe 'GET id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name' do
    context 'when job has artifacts' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }
      let(:artifact) { 'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif' }
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
      let(:public_builds) { true }

      before do
        stub_artifacts_object_storage
        job.success

        project.update!(visibility_level: visibility_level, public_builds: public_builds)

        get_artifact_file(artifact)
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { true }

          it 'allows to access artifacts', :sidekiq_might_not_need_inline do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers.to_h).to include(
              'Content-Type' => 'application/json',
              'Gitlab-Workhorse-Send-Data' => /artifacts-entry/,
              'Gitlab-Workhorse-Detect-Content-Type' => 'true'
            )
          end
        end

        context 'when project is public with builds access disabled' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { false }

          it 'rejects access to artifacts' do
            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is public with non public artifacts' do
          let(:job) { create(:ci_build, :private_artifacts, :with_private_artifacts_config, pipeline: pipeline, user: api_user) }
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { true }

          it 'rejects access and hides existence of artifacts', :sidekiq_might_not_need_inline do
            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is private' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
          let(:public_builds) { true }

          it 'rejects access and hides existence of artifacts' do
            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end
      end

      context 'when user is authorized' do
        let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        let(:public_builds) { true }

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
                  .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h).to include(
            'Content-Type' => 'application/json',
            'Gitlab-Workhorse-Send-Data' => /artifacts-entry/,
            'Gitlab-Workhorse-Detect-Content-Type' => 'true'
          )
          expect(response.parsed_body).to be_empty
        end
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'improve/awesome', sha: project.commit('improve/awesome').sha)
        end

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          get_artifact_file(artifact, 'improve/awesome')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h).to include(
            'Content-Type' => 'application/json',
            'Gitlab-Workhorse-Send-Data' => /artifacts-entry/,
            'Gitlab-Workhorse-Detect-Content-Type' => 'true'
          )
        end
      end

      context 'non-existing job' do
        shared_examples 'not found' do
          it { expect(response).to have_gitlab_http_status(:not_found) }
        end

        context 'has no such ref' do
          before do
            get_artifact_file('some/artifact', 'wrong-ref')
          end

          it_behaves_like 'not found'
        end

        context 'has no such job' do
          before do
            get_artifact_file('some/artifact', pipeline.ref, 'wrong-job-name')
          end

          it_behaves_like 'not found'
        end
      end
    end

    context 'when job does not have artifacts' do
      let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }

      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_artifact_file(artifact_path, ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/raw/#{artifact_path}", api_user), params: { job: job_name }
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/artifacts/keep' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:job) do
        create(
          :ci_build,
          :trace_artifact,
          :artifacts,
          :success,
          project: project,
          pipeline: pipeline,
          artifacts_expire_at: Time.now + 7.days
        )
      end

      it 'keeps artifacts' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(job.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:job) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
