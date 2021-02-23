# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Snippets::RepositoryStorageMove do
  describe '#as_json' do
    subject { entity.as_json }

    let(:default_storage) { 'default' }
    let(:second_storage) { 'test_second_storage' }
    let(:storage_move) { create(:snippet_repository_storage_move, :scheduled, destination_storage_name: second_storage) }
    let(:entity) { described_class.new(storage_move) }

    it 'includes basic fields' do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%W[#{default_storage} #{second_storage}])

      is_expected.to include(
        state: 'scheduled',
        source_storage_name: default_storage,
        destination_storage_name: second_storage,
        snippet: a_kind_of(Hash)
      )
    end
  end
end
