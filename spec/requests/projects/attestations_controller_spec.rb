# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AttestationsController, feature_category: :artifact_security do
  let_it_be(:project) { create(:project, :public) }
  let(:attestation) { create(:supply_chain_attestation, :with_parseable_metadata, project: project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:non_member) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    def get_index
      get project_attestations_path(project), params: {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param
      }
    end

    context 'when slsa_provenance_statement is enabled' do
      context 'when user is not authorized to read attestations' do
        let_it_be(:project) { create(:project, :private) }

        it 'returns 404' do
          sign_in(non_member)
          get_index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user can read attestations' do
        it 'renders list of attestations' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when project has more than 20 attestations' do
        before do
          create_list(:supply_chain_attestation, 21, project: project) # rubocop:disable FactoryBot/ExcessiveCreateList -- paginator is rendered when there are more than 20 attestations
        end

        it 'has paginator' do
          get_index

          expect(response.body).to have_css('.gl-pagination-item[rel=next]')
        end
      end
    end

    context 'when slsa_provenance_statement is disabled' do
      before do
        stub_feature_flags(slsa_provenance_statement: false)
      end

      it 'returns 404' do
        get_index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET show' do
    def get_show
      get project_attestation_path(project, attestation.iid)
    end

    context 'when slsa_provenance_statement is enabled' do
      context 'when user is not authorized to read attestations' do
        let_it_be(:project) { create(:project, :private) }

        it 'returns 404' do
          sign_in(non_member)
          get_show

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user can read attestation' do
        before do
          allow(SupplyChain::Attestation).to receive(:find_by_project_id_and_iid)
            .with(project.id, attestation.iid.to_s)
            .and_return(attestation)
        end

        it 'renders show view of attestation' do
          get_show

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when attestation does not exist' do
          before do
            allow(SupplyChain::Attestation).to receive(:find_by_project_id_and_iid).and_return(nil)
          end

          it 'shows error and does not render attestation details' do
            get_show

            expect(response.body).not_to include('data-testid="attestation-table"')
            expect(response.body).not_to include('data-testid="subjects-table"')
            expect(response.body).not_to include('data-testid="certificate-table"')
          end
        end

        context 'when attestation has valid metadata' do
          it 'shows attestation details' do
            get_show

            # table should be rendered
            expect(response.body).to include('data-testid="attestation-table"')
            expect(response.body).to include('data-testid="subjects-table"')
            expect(response.body).to include('data-testid="certificate-table"')

            # assert parsed subjects details (subject and digest)
            expect(response.body).to include('demodemo.gem')
            expect(response.body).to include('sha256:e6e5f634effc310a2a38bea8f71fec08eca20489763628a6e66951265df2177c')

            # assert parsed certificate details (build config URI and build config digest)
            expect(response.body).to include('http://gdk.test:3000/demos/slsa-verification-project//.gitlab-ci.yml@refs/heads/main')
            expect(response.body).to include('d75a96b5aac98f80970bec5d57819d67a8a1d7ac')
          end
        end

        context 'when attestation file cannot be parsed' do
          before do
            allow(SupplyChain::Attestation).to receive(:find_by_project_id_and_iid)
              .with(project.id, attestation.iid.to_s)
              .and_return(attestation)

            allow(Gitlab::Json).to receive(:safe_parse).and_raise(JSON::ParserError, 'Invalid JSON')
          end

          it 'logs error and does not show attestation details' do
            expect(Gitlab::AppJsonLogger).to receive(:error).with(
              message: 'Failed to parse attestation file',
              error_class: 'JSON::ParserError',
              error_message: an_instance_of(String),
              attestation_id: attestation.id,
              project_id: project.id,
              feature_category: 'artifact_security'
            ).and_call_original

            get_show

            expect(response.body).not_to include('data-testid="attestation-table"')
            expect(response.body).not_to include('data-testid="subjects-table"')
            expect(response.body).not_to include('data-testid="certificate-table"')
          end
        end

        context 'when metadata cannot be parsed' do
          before do
            allow(SupplyChain::Attestation).to receive(:find_by_project_id_and_iid)
              .with(project.id, attestation.iid.to_s)
              .and_return(attestation)

            call_count = 0
            allow(Gitlab::Json).to receive(:safe_parse).and_wrap_original do |method, arg|
              call_count += 1

              # second call is for parsing the metadata
              raise JSON::ParserError, 'Invalid JSON' if call_count == 2

              # first call parses the attestation file normally
              method.call(arg)
            end
          end

          it 'logs error and does not show attestation details' do
            expect(Gitlab::AppJsonLogger).to receive(:error).with(
              message: 'Failed to parse attestation metadata',
              error_class: 'JSON::ParserError',
              error_message: an_instance_of(String),
              attestation_id: attestation.id,
              project_id: project.id,
              feature_category: 'artifact_security'
            ).and_call_original

            get_show

            expect(response.body).not_to include('data-testid="attestation-table"')
            expect(response.body).not_to include('data-testid="subjects-table"')
            expect(response.body).not_to include('data-testid="certificate-table"')
          end
        end

        context 'when certificate cannot be parsed' do
          before do
            allow(SupplyChain::Attestation).to receive(:find_by_project_id_and_iid)
              .with(project.id, attestation.iid.to_s)
              .and_return(attestation)
          end

          it 'logs error and does not show certificate details' do
            allow(OpenSSL::X509::Certificate).to receive(:new).and_raise(OpenSSL::X509::CertificateError,
              'Invalid certificate')

            expect(Gitlab::AppJsonLogger).to receive(:error).with(
              message: 'Failed to parse attestation certificate',
              error_class: 'OpenSSL::X509::CertificateError',
              error_message: 'Invalid certificate',
              attestation_id: attestation.id,
              project_id: project.id,
              feature_category: 'artifact_security'
            ).and_call_original

            get_show

            expect(response.body).to include('data-testid="attestation-table"')
            expect(response.body).to include('data-testid="subjects-table"')
            expect(response.body).not_to include('data-testid="certificate-table"')
          end
        end
      end
    end

    context 'when slsa_provenance_statement is disabled' do
      before do
        stub_feature_flags(slsa_provenance_statement: false)
      end

      it 'returns 404' do
        get_show

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET download' do
    def download_attestation
      params = { namespace_id: project.namespace, project_id: project, id: attestation.iid }

      get download_namespace_project_attestation_path(**params)
    end

    context 'when slsa_provenance_statement is enabled' do
      context 'when attestation is readable' do
        it 'returns attestation file',
          quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/18579' do
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
