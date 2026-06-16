# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketImport::ClientFactory, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_url: 'https://bitbucket.org/repo/repo.git',
      import_data_attributes: {
        credentials: { token: 'token-1', refresh_token: 'refresh-1', expires_at: 1.hour.ago.to_i, expires_in: 7200 }
      }
    )
  end

  describe '.for' do
    subject(:client) { described_class.for(project) }

    it 'returns a Bitbucket::Client' do
      expect(client).to be_a(Bitbucket::Client)
    end

    it 'delegates refresh! to a TokenRefreshStrategy bound to the project' do
      expect_next_instance_of(Import::BitbucketImport::TokenRefreshStrategy, project) do |strategy|
        expect(strategy).to receive(:refresh)
      end

      client.connection.refresh!
    end
  end
end
