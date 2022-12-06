# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::CreateAsymmetricJwtService, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:jira_connect_installation) { create(:jira_connect_installation) }

    let(:service) { described_class.new(jira_connect_installation) }

    subject(:jwt_token) { service.execute }

    it 'raises an error' do
      expect { jwt_token }.to raise_error(ArgumentError, 'jira_connect_installation is not a proxy installation')
    end

    context 'with proxy installation' do
      let_it_be(:jira_connect_installation) { create(:jira_connect_installation, instance_url: 'https://gitlab.test') }

      let(:public_key_id) { Atlassian::Jwt.decode(jwt_token, nil, false, algorithm: 'RS256').last['kid'] }
      let(:public_key_cdn) { 'https://gitlab.com/-/jira_connect/public_keys/' }
      let(:jwt_verification_claims) do
        {
          aud: 'https://gitlab.test/-/jira_connect',
          iss: jira_connect_installation.client_key,
          qsh: Atlassian::Jwt.create_query_string_hash('https://gitlab.test/-/jira_connect/events/installed', 'POST', 'https://gitlab.test/-/jira_connect')
        }
      end

      subject(:jwt_token) { service.execute }

      it 'stores the public key' do
        expect { JiraConnect::PublicKey.find(public_key_id) }.not_to raise_error
      end

      it 'is produces a valid JWT' do
        public_key = OpenSSL::PKey.read(JiraConnect::PublicKey.find(public_key_id).key)
        options = jwt_verification_claims.except(:qsh).merge({ verify_aud: true, verify_iss: true, algorithm: 'RS256' })

        decoded_token = Atlassian::Jwt.decode(jwt_token, public_key, true, options).first

        expect(decoded_token).to eq(jwt_verification_claims.stringify_keys)
      end
    end
  end
end
