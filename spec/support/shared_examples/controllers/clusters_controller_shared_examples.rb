# frozen_string_literal: true

RSpec.shared_examples 'GET new cluster shared examples' do
  describe 'EKS cluster' do
    context 'user already has an associated AWS role' do
      let!(:role) { create(:aws_role, user: user) }

      it 'does not create an Aws::Role record' do
        expect { go(provider: 'aws') }.not_to change { Aws::Role.count }

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:aws_role)).to eq(role)
      end
    end

    context 'user does not have an associated AWS role' do
      it 'creates an Aws::Role record' do
        expect { go(provider: 'aws') }.to change { Aws::Role.count }

        expect(response).to have_gitlab_http_status(:ok)

        role = assigns(:aws_role)
        expect(role.user).to eq(user)
        expect(role.role_arn).to be_nil
        expect(role.role_external_id).to be_present
      end
    end
  end
end

RSpec.shared_examples ':certificate_based_clusters feature flag index responses' do
  context 'feature flag is disabled' do
    before do
      stub_feature_flags(certificate_based_clusters: false)
    end

    it 'does not list any clusters' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:clusters)).to be_empty
    end
  end
end

RSpec.shared_examples ':certificate_based_clusters feature flag controller responses' do
  context 'feature flag is disabled' do
    before do
      stub_feature_flags(certificate_based_clusters: false)
    end

    it 'responds with :not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
