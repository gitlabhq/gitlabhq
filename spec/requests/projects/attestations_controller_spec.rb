# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AttestationsController, feature_category: :artifact_security do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:attestation) { create(:supply_chain_attestation, project: project) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  describe 'GET download' do
    def download_attestation
      params = { namespace_id: project.namespace, project_id: project, id: attestation.iid }

      get download_namespace_project_attestation_path(**params)
    end

    context 'when slsa_provenance_statement is enabled' do
      context 'when attestation is readable' do
        it 'returns attestation file' do
          download_attestation

          filename = attestation.file.filename

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Disposition'])
            .to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
          expect(response.headers['X-Sendfile']).to eq(attestation.file.path)
        end
      end

      context 'when attestation is not readable' do
        let_it_be(:project) { create(:project, :private) }

        it 'returns 404' do
          download_attestation

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when slsa_provenance_statement is disabled' do
      before do
        stub_feature_flags(slsa_provenance_statement: false)
      end

      it 'returns 404' do
        download_attestation

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
