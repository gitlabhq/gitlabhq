# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::CompositeIdentityAuthor, feature_category: :audit_events do
  let_it_be(:service_account) { build_stubbed(:user, name: 'My Service Account') }
  let_it_be(:human_author) { build_stubbed(:user) }

  subject(:author) { described_class.new(service_account, human_author: human_author) }

  describe '#id' do
    it 'delegates to the service account so author_id stays attributed to the SA' do
      expect(author.id).to eq(service_account.id)
    end
  end

  describe '#name' do
    it 'renders the service account name with the authorizing human reference' do
      expect(author.name).to eq("My Service Account on behalf of #{human_author.to_reference}")
    end

    context 'when both names exceed the per-name budget' do
      let_it_be(:service_account) { build_stubbed(:user, name: 'S' * 200) }
      let_it_be(:human_author) { build_stubbed(:user, username: 'u' * 200) }

      it 'truncates each name evenly and stays within the max length' do
        service_account_name, human_reference = author.name.split(described_class::ON_BEHALF_OF)

        expect(author.name.length).to be <= described_class::AUTHOR_NAME_MAX_LENGTH
        expect(service_account_name.length).to eq(described_class::MAX_NAME_LENGTH)
        expect(human_reference.length).to eq(described_class::MAX_NAME_LENGTH)
        expect(service_account_name).to end_with('...')
        expect(human_reference).to end_with('...')
      end
    end
  end

  describe 'delegation' do
    it 'delegates unknown methods to the service account' do
      expect(author.username).to eq(service_account.username)
    end
  end
end
