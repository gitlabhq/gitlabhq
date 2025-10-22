# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SupplyChain::Attestations, feature_category: :artifact_security do
  include HttpBasicAuthHelpers
  include DependencyProxyHelpers

  include HttpIOHelpers

  let_it_be(:project, reload: true) do
    create(:project, :repository)
  end

  let_it_be(:other_project, reload: true) do
    create(:project, :repository)
  end

  let_it_be(:pipeline, reload: true) do
    create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
  end

  let(:developer) { create(:user) }
  let(:user) { developer }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }

  let!(:job) do
    create(:ci_build, :success, :tags, pipeline: pipeline)
  end

  before do
    project.add_developer(developer)
  end

  describe 'GET /projects/:id/attestations/:subject_digest' do
    let_it_be(:subject_digest) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa" }
    let_it_be(:other_subject_digest) { "fffffee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa" }
    let_it_be(:attestation) { create(:supply_chain_attestation, project: project, subject_digest: subject_digest) }
    let_it_be(:other_attestation) do
      create(:supply_chain_attestation, project: other_project, subject_digest: subject_digest)
    end

    let(:get_attestations_other_project) do
      url = "/projects/#{other_project.id}/attestations/#{subject_digest}"
      get api(url, api_user)
    end

    subject(:get_attestations) do
      url = target_url
      get api(url, api_user)
    end

    shared_examples 'when an attestation exists' do
      it 'returns the right attestations in the response' do
        get_attestations

        expect(json_response.length).to eq(1)
        expect(json_response[0]).to include({
          "id" => attestation.id,
          "project_id" => attestation.project_id,
          "expire_at" => attestation.expire_at,
          "build_id" => attestation.build_id,
          "status" => "success",
          "predicate_kind" => "provenance",
          "predicate_type" => "https://slsa.dev/provenance/v1",
          "subject_digest" => subject_digest
        })
      end

      context 'when slsa_provenance_statement is disabled' do
        before do
          stub_feature_flags(slsa_provenance_statement: false)
        end

        it 'returns 404' do
          get_attestations

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      describe 'authorization checks' do
        context 'when user is anonymous' do
          let(:api_user) { nil }

          context 'when project is public' do
            before do
              project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
              project.update_column(:public_builds, true)
            end

            it 'allows to access attestations' do
              get_attestations

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'when project is private' do
            it 'rejects access and hides existence of attestations' do
              get_attestations

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when user is guest' do
          let(:api_user) { guest }

          it 'allows to access attestations if has access' do
            get_attestations

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'disallows access if does not have access' do
            get_attestations_other_project

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when user is developer' do
          let(:api_user) { developer }

          it 'allows to access attestations if has access' do
            get_attestations

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'disallows access if does not have access' do
            get_attestations_other_project

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when user is reporter' do
          let(:api_user) { reporter }

          it 'allows to access attestations if has access' do
            get_attestations

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'disallows access if does not have access' do
            get_attestations_other_project

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'when accessing via the project id' do
      let(:target_url) { "/projects/#{project.id}/attestations/#{subject_digest}" }

      include_examples 'when an attestation exists'
    end

    context 'when accessing via the project full_path' do
      let(:target_url) { "/projects/#{CGI.escape(project.full_path)}/attestations/#{subject_digest}" }

      include_examples 'when an attestation exists'
    end

    context 'when an attestation does not exist' do
      let(:target_url) do
        "/projects/#{project.id}/attestations/cbe6fc257a1cd3032c3c4bff38653cd14502f213000745006337dee7dcfc4de4"
      end

      it 'returns an empty response' do
        get_attestations

        expect(json_response.length).to eq(0)
      end
    end
  end
end
