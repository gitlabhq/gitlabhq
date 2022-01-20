# frozen_string_literal: true

require 'spec_helper'

# Mock Types
MockGoogleOAuth2Credentials = Struct.new(:app_id, :app_secret)
MockServiceAccount = Struct.new(:project_id, :unique_id)

RSpec.describe GoogleCloud::CreateServiceAccountsService do
  describe '#execute' do
    before do
      allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                .with('google_oauth2')
                                                .and_return(MockGoogleOAuth2Credentials.new('mock-app-id', 'mock-app-secret'))

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:create_service_account)
                           .and_return(MockServiceAccount.new('mock-project-id', 'mock-unique-id'))
        allow(client).to receive(:create_service_account_key)
                           .and_return('mock-key')
      end
    end

    it 'creates unprotected vars', :aggregate_failures do
      project = create(:project)

      service = described_class.new(
        project,
        nil,
        google_oauth2_token: 'mock-token',
        gcp_project_id: 'mock-gcp-project-id',
        environment_name: '*'
      )

      response = service.execute

      expect(response.status).to eq(:success)
      expect(response.message).to eq('Service account generated successfully')
      expect(project.variables.count).to eq(3)
      expect(project.variables.first.protected).to eq(false)
      expect(project.variables.second.protected).to eq(false)
      expect(project.variables.third.protected).to eq(false)
    end
  end
end
