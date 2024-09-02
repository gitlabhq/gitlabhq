# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Clusters::ReceptiveAgent, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }
  let_it_be(:project) { agent.project }

  subject { described_class.new(config).as_json }

  context 'with public key auth' do
    let(:config) { create(:cluster_agent_url_configuration, :public_key_auth, agent: agent) }

    it do
      is_expected.to include(
        id: config.agent_id,
        jwt: { private_key: Base64.strict_encode64(config.private_key) }
      )
    end
  end

  context 'with certificate auth' do
    let(:config) { create(:cluster_agent_url_configuration, :certificate_auth, agent: agent) }

    it do
      is_expected.to include(
        id: config.agent_id,
        mtls: {
          client_cert: config.client_cert,
          client_key: config.client_key
        }
      )
    end
  end

  context 'with tls host and ca cert' do
    let(:config) do
      create(:cluster_agent_url_configuration, :certificate_auth, agent: agent, tls_host: 'any-host.example.com',
        ca_cert: File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')))
    end

    it do
      is_expected.to include(
        id: config.agent_id,
        ca_cert: config.ca_cert,
        tls_host: config.tls_host
      )
    end
  end
end
