# frozen_string_literal: true

shared_examples 'new cluster action' do |parent_type:|
  it 'renders the new template' do
    go

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to render_template(:new)
  end

  context 'when omniauth has been configured' do
    let(:key) { 'secret-key' }
    let(:session_key_for_redirect_uri) do
      GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
    end

    before do
      allow(SecureRandom).to receive(:hex).and_return(key)
    end

    it 'has authorize_url' do
      expect(controller).to receive(:render).with(
        'shared/clusters/new',
        locals: {
          gcp_cluster: anything,
          user_cluster: anything,
          authorize_url: /#{key}/,
          valid_gcp_token: anything
        }
      ).and_call_original

      go
    end

    it 'has redirect url after authorize' do
      go

      google_redirect_url = case parent_type
                            when :project
                              new_project_cluster_path(assigns(:project))
                            end

      expect(session[session_key_for_redirect_uri]).to eq(google_redirect_url)
    end
  end

  context 'when omniauth has not configured' do
    before do
      stub_omniauth_setting(providers: [])
    end

    it 'does not have authorize_url' do
      expect(controller).to receive(:render).with(
        'shared/clusters/new',
        locals: {
          gcp_cluster: anything,
          user_cluster: anything,
          authorize_url: nil,
          valid_gcp_token: anything
        }
      ).and_call_original

      go
    end
  end

  context 'when access token is expired' do
    before do
      stub_google_api_expired_token
    end

    it 'does not have valid_gcp_token' do
      expect(controller).to receive(:render).with(
        'shared/clusters/new',
        locals: {
          gcp_cluster: anything,
          user_cluster: anything,
          authorize_url: anything,
          valid_gcp_token: false
        }
      ).and_call_original

      go
    end
  end

  context 'when access token is not stored in session' do
    it 'does not have valid_gcp_token' do
      expect(controller).to receive(:render).with(
        'shared/clusters/new',
        locals: {
          gcp_cluster: anything,
          user_cluster: anything,
          authorize_url: anything,
          valid_gcp_token: false
        }
      ).and_call_original

      go
    end
  end
end

shared_examples 'create_gcp action' do |parent_type:|
  context 'when access token is valid' do
    let(:first_cluster) do
      case parent_type
      when :project
        project.clusters.first
      end
    end

    let(:redirect) do
      case parent_type
      when :project
        project_cluster_path(project, first_cluster)
      end
    end

    before do
      stub_google_api_validate_token
    end

    it 'creates a new cluster' do
      expect(ClusterProvisionWorker).to receive(:perform_async)
      expect { go }.to change { Clusters::Cluster.count }
        .and change { Clusters::Providers::Gcp.count }
      expect(response).to redirect_to(redirect)
      expect(first_cluster).to be_gcp
      expect(first_cluster).to be_kubernetes
      expect(first_cluster.provider_gcp).to be_legacy_abac
    end

    context 'when legacy_abac param is false' do
      let(:legacy_abac_param) { 'false' }

      it 'creates a new cluster with legacy_abac_disabled' do
        expect(ClusterProvisionWorker).to receive(:perform_async)
        expect { go }.to change { Clusters::Cluster.count }
          .and change { Clusters::Providers::Gcp.count }
        expect(first_cluster.provider_gcp).not_to be_legacy_abac
      end
    end
  end
end

shared_examples 'create_user action' do |parent_type:|
  let(:first_cluster) do
    case parent_type
    when :project
      project.clusters.first
    end
  end

  let(:redirect) do
    case parent_type
    when :project
      project_cluster_path(project, first_cluster)
    end
  end

  context 'when creates a cluster' do
    it 'creates a new cluster' do
      expect(ClusterProvisionWorker).to receive(:perform_async)

      expect { go }.to change { Clusters::Cluster.count }
        .and change { Clusters::Platforms::Kubernetes.count }

      expect(response).to redirect_to(redirect)

      expect(first_cluster).to be_user
      expect(first_cluster).to be_kubernetes
    end
  end

  context 'when creates a RBAC-enabled cluster' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          platform_kubernetes_attributes: {
            api_url: 'http://my-url',
            token: 'test',
            namespace: 'aaa',
            authorization_type: 'rbac'
          }
        }
      }
    end

    it 'creates a new cluster' do
      expect(ClusterProvisionWorker).to receive(:perform_async)

      expect { go }.to change { Clusters::Cluster.count }
        .and change { Clusters::Platforms::Kubernetes.count }

      expect(response).to redirect_to(redirect)

      expect(first_cluster).to be_user
      expect(first_cluster).to be_kubernetes
      expect(first_cluster).to be_platform_kubernetes_rbac
    end
  end
end
