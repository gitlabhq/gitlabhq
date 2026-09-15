# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SshCertificatesController, :enable_admin_mode,
  feature_category: :source_code_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  describe 'GET /admin/ssh_certificates' do
    subject(:get_index) { get admin_ssh_certificates_path }

    context 'when signed in as an admin' do
      before do
        sign_in(admin)
      end

      it 'renders the index page' do
        get_index

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(instance_ssh_certificates: false)
        end

        it 'returns not found' do
          get_index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'on GitLab.com', :saas do
        it 'returns not found' do
          get_index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when signed in as a non-admin user' do
      before do
        sign_in(user)
      end

      it 'returns not found' do
        get_index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
