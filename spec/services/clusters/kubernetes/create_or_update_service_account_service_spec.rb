# frozen_string_literal: true
require 'spec_helper'

describe Clusters::Kubernetes::CreateOrUpdateServiceAccountService do
  include KubernetesHelpers

  let(:api_url) { 'http://111.111.111.111' }
  let(:platform_kubernetes) { cluster.platform_kubernetes }
  let(:cluster_project) { cluster.cluster_project }
  let(:project) { cluster_project.project }
  let(:cluster) do
    create(:cluster,
           :project, :provided_by_gcp,
           platform_kubernetes: create(:cluster_platform_kubernetes, :configured))
  end

  let(:kubeclient) do
    Gitlab::Kubernetes::KubeClient.new(
      api_url,
      auth_options: { username: 'admin', password: 'xxx' }
    )
  end

  shared_examples 'creates service account and token' do
    it 'creates a kubernetes service account' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts").with(
        body: hash_including(
          kind: 'ServiceAccount',
          metadata: { name: service_account_name, namespace: namespace }
        )
      )
    end

    it 'creates a kubernetes secret' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/secrets").with(
        body: hash_including(
          kind: 'Secret',
          metadata: {
            name: token_name,
            namespace: namespace,
            annotations: {
              'kubernetes.io/service-account.name': service_account_name
            }
          },
          type: 'kubernetes.io/service-account-token'
        )
      )
    end
  end

  before do
    stub_kubeclient_discover(api_url)
    stub_kubeclient_get_namespace(api_url, namespace: namespace)

    stub_kubeclient_get_service_account_error(api_url, service_account_name, namespace: namespace)
    stub_kubeclient_create_service_account(api_url, namespace: namespace)

    stub_kubeclient_get_secret_error(api_url, token_name, namespace: namespace)
    stub_kubeclient_create_secret(api_url, namespace: namespace)
  end

  describe '.gitlab_creator' do
    let(:namespace) { 'default' }
    let(:service_account_name) { 'gitlab' }
    let(:token_name) { 'gitlab-token' }

    subject { described_class.gitlab_creator(kubeclient, rbac: rbac).execute }

    context 'with ABAC cluster' do
      let(:rbac) { false }

      it_behaves_like 'creates service account and token'
    end

    context 'with RBAC cluster' do
      let(:rbac) { true }
      let(:cluster_role_binding_name) { 'gitlab-admin' }

      before do
        cluster.platform_kubernetes.rbac!

        stub_kubeclient_get_cluster_role_binding_error(api_url, cluster_role_binding_name)
        stub_kubeclient_create_cluster_role_binding(api_url)
      end

      it_behaves_like 'creates service account and token'

      it 'creates a cluster role binding with cluster-admin access' do
        subject

        expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings").with(
          body: hash_including(
            kind: 'ClusterRoleBinding',
            metadata: { name: 'gitlab-admin' },
            roleRef: {
              apiGroup: 'rbac.authorization.k8s.io',
              kind: 'ClusterRole',
              name: 'cluster-admin'
            },
            subjects: [
              {
                kind: 'ServiceAccount',
                name: service_account_name,
                namespace: namespace
              }
            ]
          )
        )
      end
    end
  end

  describe '.namespace_creator' do
    let(:namespace) { "#{project.path}-#{project.id}" }
    let(:service_account_name) { "#{namespace}-service-account" }
    let(:token_name) { "#{namespace}-token" }

    subject do
      described_class.namespace_creator(
        kubeclient,
        service_account_name: service_account_name,
        service_account_namespace: namespace,
        rbac: rbac
      ).execute
    end

    context 'with ABAC cluster' do
      let(:rbac) { false }

      it_behaves_like 'creates service account and token'
    end

    context 'With RBAC enabled cluster' do
      let(:rbac) { true }
      let(:role_binding_name) { "gitlab-#{namespace}"}

      before do
        cluster.platform_kubernetes.rbac!

        stub_kubeclient_get_role_binding_error(api_url, role_binding_name, namespace: namespace)
        stub_kubeclient_create_role_binding(api_url, namespace: namespace)
        stub_kubeclient_put_role(api_url, Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_NAME, namespace: namespace)
        stub_kubeclient_put_role_binding(api_url, Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_BINDING_NAME, namespace: namespace)
        stub_kubeclient_put_role(api_url, Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_NAME, namespace: namespace)
        stub_kubeclient_put_role_binding(api_url, Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_BINDING_NAME, namespace: namespace)
      end

      it_behaves_like 'creates service account and token'

      it 'creates a namespaced role binding with edit access' do
        subject

        expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings").with(
          body: hash_including(
            kind: 'RoleBinding',
            metadata: { name: "gitlab-#{namespace}", namespace: "#{namespace}" },
            roleRef: {
              apiGroup: 'rbac.authorization.k8s.io',
              kind: 'ClusterRole',
              name: 'edit'
            },
            subjects: [
              {
                kind: 'ServiceAccount',
                name: service_account_name,
                namespace: namespace
              }
            ]
          )
        )
      end

      it 'creates a role binding granting crossplane database permissions to the service account' do
        subject

        expect(WebMock).to have_requested(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings/#{Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_BINDING_NAME}").with(
          body: hash_including(
            metadata: {
              name: Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_BINDING_NAME,
              namespace: namespace
            },
            roleRef: {
              apiGroup: 'rbac.authorization.k8s.io',
              kind: 'Role',
              name: Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_NAME
            },
            subjects: [
              {
                kind: 'ServiceAccount',
                name: service_account_name,
                namespace: namespace
              }
            ]
          )
        )
      end

      it 'creates a role and role binding granting knative serving permissions to the service account' do
        subject

        expect(WebMock).to have_requested(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/roles/#{Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_NAME}").with(
          body: hash_including(
            metadata: {
              name: Clusters::Kubernetes::GITLAB_KNATIVE_SERVING_ROLE_NAME,
              namespace: namespace
            },
            rules: [{
              apiGroups: %w(serving.knative.dev),
              resources: %w(configurations configurationgenerations routes revisions revisionuids autoscalers services),
              verbs: %w(get list create update delete patch watch)
            }]
          )
        )
      end

      it 'creates a role and role binding granting crossplane database permissions to the service account' do
        subject

        expect(WebMock).to have_requested(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/roles/#{Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_NAME}").with(
          body: hash_including(
            metadata: {
              name: Clusters::Kubernetes::GITLAB_CROSSPLANE_DATABASE_ROLE_NAME,
              namespace: namespace
            },
            rules: [{
              apiGroups: %w(database.crossplane.io),
              resources: %w(postgresqlinstances),
              verbs: %w(get list create watch)
            }]
          )
        )
      end
    end
  end
end
