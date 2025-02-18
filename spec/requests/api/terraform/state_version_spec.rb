# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Terraform::StateVersion, feature_category: :infrastructure_as_code do
  include HttpBasicAuthHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:user_without_access) { create(:user) }

  let_it_be_with_reload(:state) { create(:terraform_state, project: project) }

  let!(:versions) { create_list(:terraform_state_version, 3, terraform_state: state) }

  let(:current_user) { maintainer }
  let(:auth_header) { user_basic_auth_header(current_user) }
  let(:project_id) { project.id }
  let(:state_name) { state.name }
  let(:version) { versions.last }
  let(:version_serial) { version.version }
  let(:state_version_path) { "/projects/#{project_id}/terraform/state/#{state_name}/versions/#{version_serial}" }

  before do
    stub_config(terraform_state: { enabled: true })
  end

  describe 'GET /projects/:id/terraform/state/:name/versions/:serial' do
    subject(:request) { get api(state_version_path), headers: auth_header }

    it_behaves_like 'it depends on value of the `terraform_state.enabled` config'

    context 'with invalid authentication' do
      let(:auth_header) { basic_auth_header('bad', 'token') }

      it 'returns unauthorized status' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with no authentication' do
      let(:auth_header) { nil }

      it 'returns unauthorized status' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'personal acceess token authentication' do
      context 'with maintainer permissions' do
        let(:current_user) { maintainer }

        it 'returns the state contents at the given version' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(version.file.read)
        end

        context 'for a project that does not exist' do
          let(:project_id) { '0000' }

          it 'returns not found status' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with developer permissions' do
        let(:current_user) { developer }

        it 'returns the state contents at the given version' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(version.file.read)
        end
      end

      context 'with no permissions' do
        let(:current_user) { user_without_access }

        it 'returns not found status' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'job token authentication' do
      let(:auth_header) { job_basic_auth_header(job) }

      it_behaves_like 'enforcing job token policies', :read_terraform_state do
        let_it_be(:user) { maintainer }
        let(:auth_header) { job_basic_auth_header(target_job) }
      end

      context 'with maintainer permissions' do
        let(:job) { create(:ci_build, status: :running, project: project, user: maintainer) }

        it 'returns the state contents at the given version' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(version.file.read)
        end

        it 'returns unauthorized status if the the job is not running' do
          job.update!(status: :failed)
          request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'for a project that does not exist' do
          let(:project_id) { '0000' }

          it 'returns not found status' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with developer permissions' do
        let(:job) { create(:ci_build, status: :running, project: project, user: developer) }

        it 'returns the state contents at the given version' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(version.file.read)
        end
      end

      context 'with no permissions' do
        let(:current_user) { user_without_access }
        let(:job) { create(:ci_build, status: :running, user: current_user) }

        it 'returns forbidden status' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/terraform/state/:name/versions/:serial' do
    subject(:request) { delete api(state_version_path), headers: auth_header }

    it_behaves_like 'enforcing job token policies', :admin_terraform_state do
      let_it_be(:user) { maintainer }
      let(:auth_header) { job_basic_auth_header(target_job) }
    end

    it_behaves_like 'it depends on value of the `terraform_state.enabled` config', { success_status: :no_content }

    context 'with invalid authentication' do
      let(:auth_header) { basic_auth_header('bad', 'token') }

      it 'returns unauthorized status' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with no authentication' do
      let(:auth_header) { nil }

      it 'returns unauthorized status' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with maintainer permissions' do
      let(:current_user) { maintainer }

      it 'deletes the version' do
        expect { request }.to change { Terraform::StateVersion.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'version does not exist' do
        let(:version_serial) { -1 }

        it 'does not delete a version' do
          expect { request }.to change { Terraform::StateVersion.count }.by(0)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with developer permissions' do
      let(:current_user) { developer }

      it 'returns forbidden status' do
        expect { request }.to change { Terraform::StateVersion.count }.by(0)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with no permissions' do
      let(:current_user) { user_without_access }

      it 'returns not found status' do
        expect { request }.to change { Terraform::StateVersion.count }.by(0)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
