# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Clusters::AgentUrlConfiguration, feature_category: :deployment_management do
  subject(:entity) { described_class.new(url_configuration).as_json }

  context 'when public key auth' do
    let_it_be(:url_configuration) { create(:cluster_agent_url_configuration, :public_key_auth) }

    it 'includes fields' do
      expect(entity).to include(
        id: url_configuration.id,
        agent_id: url_configuration.agent.id,
        url: url_configuration.url,
        ca_cert: url_configuration.ca_cert,
        tls_host: url_configuration.tls_host
      )

      expect(Base64.decode64(entity[:public_key])).to eq(url_configuration.public_key)
    end
  end

  context 'when certificate auth' do
    let_it_be(:url_configuration) { create(:cluster_agent_url_configuration, :certificate_auth) }

    it 'includes fields' do
      expect(entity).to include(
        id: url_configuration.id,
        agent_id: url_configuration.agent.id,
        url: url_configuration.url,
        ca_cert: url_configuration.ca_cert,
        tls_host: url_configuration.tls_host
      )

      expect(Base64.decode64(entity[:client_cert])).to eq(url_configuration.client_cert)
    end
  end
end
