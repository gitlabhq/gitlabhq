# frozen_string_literal: true

require "spec_helper"

describe API::LsifData do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:commit) { project.commit }

  describe 'GET lsif/info' do
    subject do
      endpoint_path = "/projects/#{project.id}/commits/#{commit.id}/lsif/info"

      get api(endpoint_path, user), params: { paths: ['main.go', 'morestrings/reverse.go'] }

      response
    end

    context 'user does not have access to the project' do
      before do
        project.add_guest(user)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'user has access to the project' do
      before do
        project.add_reporter(user)
      end

      context 'there is no job artifact for the passed commit' do
        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'lsif data is stored as a job artifact' do
        let!(:pipeline) { create(:ci_pipeline, project: project, sha: commit.id) }
        let!(:artifact) { create(:ci_job_artifact, :lsif, job: create(:ci_build, pipeline: pipeline)) }

        context 'code_navigation feature is disabled' do
          before do
            stub_feature_flags(code_navigation: false)
          end

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end

        it 'returns code navigation info for a given path', :aggregate_failures do
          expect(subject).to have_gitlab_http_status(:ok)

          data_for_main = response.parsed_body['main.go']
          expect(data_for_main.last).to eq({
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

          data_for_reverse = response.parsed_body['morestrings/reverse.go']
          expect(data_for_reverse.last).to eq({
            'end_char' => 9,
            'end_line' => 7,
            'start_char' => 8,
            'start_line' => 7,
            'definition_url' => project_blob_path(project, "#{commit.id}/morestrings/reverse.go", anchor: 'L6'),
            'hover' => [{
              'language' => 'go',
              'value' => Gitlab::Highlight.highlight(nil, 'var b string', language: 'go')
            }]
          })
        end

        context 'the stored file is too large' do
          before do
            allow_any_instance_of(JobArtifactUploader).to receive(:cached_size).and_return(20.megabytes)
          end

          it { is_expected.to have_gitlab_http_status(:payload_too_large) }
        end

        context 'the user does not have access to the pipeline' do
          let(:project) { create(:project, :repository, builds_access_level: ProjectFeature::DISABLED) }

          it { is_expected.to have_gitlab_http_status(:forbidden) }
        end
      end
    end
  end
end
