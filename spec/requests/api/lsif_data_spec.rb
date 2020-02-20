# frozen_string_literal: true

require "spec_helper"

describe API::LsifData do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:commit) { project.commit }

  describe 'GET lsif/info' do
    let(:endpoint_path) { "/projects/#{project.id}/commits/#{commit.id}/lsif/info" }

    context 'user does not have access to the project' do
      before do
        project.add_guest(user)
      end

      it 'returns 403' do
        get api(endpoint_path, user), params: { path: 'main.go' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'user has access to the project' do
      before do
        project.add_reporter(user)
      end

      context 'code_navigation feature is disabled' do
        before do
          stub_feature_flags(code_navigation: false)
        end

        it 'returns 404' do
          get api(endpoint_path, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'there is no job artifact for the passed commit' do
        it 'returns 404' do
          get api(endpoint_path, user), params: { path: 'main.go' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'lsif data is stored as a job artifact' do
        let!(:pipeline) { create(:ci_pipeline, project: project, sha: commit.id) }
        let!(:artifact) { create(:ci_job_artifact, :lsif, job: create(:ci_build, pipeline: pipeline)) }

        it 'returns code navigation info for a given path' do
          get api(endpoint_path, user), params: { path: 'main.go' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.parsed_body.last).to eq({
            'end_char' => 18,
            'end_line' => 8,
            'start_char' => 13,
            'start_line' => 8,
            'definition_url' => project_blob_path(project, "#{commit.id}/morestrings/reverse.go", anchor: 'L5'),
            'hover' => [{
              'language' => 'go',
              'value' => Gitlab::Highlight.highlight(nil, 'func Func2(i int) string', language: 'go')
            }]
          })
        end

        context 'the stored file is too large' do
          it 'returns 413' do
            allow_any_instance_of(JobArtifactUploader).to receive(:cached_size).and_return(20.megabytes)

            get api(endpoint_path, user), params: { path: 'main.go' }

            expect(response).to have_gitlab_http_status(:payload_too_large)
          end
        end

        context 'the user does not have access to the pipeline' do
          let(:project) { create(:project, :repository, builds_access_level: ProjectFeature::DISABLED) }

          it 'returns 403' do
            get api(endpoint_path, user), params: { path: 'main.go' }

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end
end
