require 'spec_helper'

describe Ci::IntegrateClusterService do
  describe '#execute' do
    let(:cluster) { create(:gcp_cluster, :custom_project_namespace) }
    let(:endpoint) { '123.123.123.123' }
    let(:ca_cert) { 'ca_cert_xxx' }
    let(:token) { 'token_xxx' }
    let(:username) { 'username_xxx' }
    let(:password) { 'password_xxx' }

    before do
      described_class
        .new.execute(cluster, endpoint, ca_cert, token, username, password)

      cluster.reload
    end

    context 'when correct params' do
      it 'creates a cluster object' do
        expect(cluster.endpoint).to eq(endpoint)
        expect(cluster.ca_cert).to eq(ca_cert)
        expect(cluster.kubernetes_token).to eq(token)
        expect(cluster.username).to eq(username)
        expect(cluster.password).to eq(password)
        expect(cluster.service.active).to be_truthy
        expect(cluster.service.api_url).to eq(cluster.api_url)
        expect(cluster.service.ca_pem).to eq(ca_cert)
        expect(cluster.service.namespace).to eq(cluster.project_namespace)
        expect(cluster.service.token).to eq(token)
      end
    end

    context 'when invalid params' do
      let(:endpoint) { nil }

      it 'sets an error to cluster object' do
        expect(cluster).to be_errored
      end
    end
  end
end
