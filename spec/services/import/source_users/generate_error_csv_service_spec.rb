# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::GenerateErrorCsvService, feature_category: :importers do
  let(:data) do
    [
      {
        source_host: 'https://github.com',
        import_type: :github,
        source_user_identifier: 'alice_1',
        source_user_name: 'Alice Alison',
        source_username: 'alice',
        gitlab_username: 'alice-gl',
        gitlab_public_email: 'alice@example.com',
        error: 'Could not match user'
      },
      {
        source_host: 'https://gitlab.example',
        import_type: :direct_transfer,
        source_user_identifier: 'bob_1',
        source_user_name: 'Bob Bobson',
        source_username: 'bob',
        gitlab_username: 'bob-gl',
        gitlab_public_email: 'bob@example.com',
        error: 'Insufficient permissions'
      }
    ]
  end

  let(:service) { described_class.new(data) }

  describe '#execute' do
    subject(:result) { service.execute.payload }

    it 'generates a CSV from the input array' do
      expect(result).to eq(<<~CSV)
        Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email,Error
        https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com,Could not match user
        https://gitlab.example,direct_transfer,bob_1,Bob Bobson,bob,bob-gl,bob@example.com,Insufficient permissions
      CSV
    end
  end
end
