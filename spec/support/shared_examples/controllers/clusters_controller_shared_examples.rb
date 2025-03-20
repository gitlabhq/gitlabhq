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

RSpec.shared_examples 'cluster update migration' do |_resource_type, user_type|
  let(:issue) { create(:issue) }
  let(:issue_url) { project_issue_url(issue.project, issue) }
  let(:current_user) { send(user_type) }

  let(:params) do
    {
      cluster_migration: {
        issue_url: issue_url
      }
    }
  end

  describe 'functionality' do
    let(:service) { instance_double(Clusters::Migration::UpdateService) }
    let(:service_response) { ServiceResponse.success }

    before do
      allow(Clusters::Migration::UpdateService).to receive(:new).and_return(service)
      allow(service).to receive(:execute).and_return(service_response)
    end

    it 'passes the correct parameters to the service' do
      go

      expect(Clusters::Migration::UpdateService).to have_received(:new).with(
        cluster,
        hash_including(current_user: current_user)
      )
    end

    context 'when update is successful' do
      it 'redirects to cluster page with migrate tab' do
        go

        expect(response).to redirect_to(redirect_path)
        expect(flash[:notice]).to eq(s_('ClusterIntegration|Migration issue updated successfully'))
      end
    end

    context 'when update fails' do
      let(:service_response) { ServiceResponse.error(message: 'Error message') }

      it 'redirects to cluster page with error message' do
        go

        expect(response).to redirect_to(redirect_path)
        expect(flash[:alert]).to eq(format(s_('ClusterIntegration|Migration issue update - failed: "%{error}"'),
          error: 'Error message'))
      end
    end

    context 'with invalid issue URL' do
      let(:params) do
        {
          cluster_migration: {
            issue_url: 'invalid-url'
          }
        }
      end

      let(:service_response) { ServiceResponse.error(message: 'Invalid issue URL') }

      before do
        allow(Clusters::Migration::UpdateService).to receive(:new)
          .with(cluster, hash_including(issue_url: 'invalid-url'))
          .and_return(service)
      end

      it 'redirects with error message' do
        go

        expect(response).to redirect_to(redirect_path)
        expect(flash[:alert]).to eq(format(s_('ClusterIntegration|Migration issue update - failed: "%{error}"'),
          error: 'Invalid issue URL'))
      end
    end
  end
end
