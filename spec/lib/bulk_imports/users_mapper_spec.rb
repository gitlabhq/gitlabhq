# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UsersMapper, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:import) { create(:bulk_import, user: user) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import) }

  let(:context) do
    instance_double(
      BulkImports::Pipeline::Context,
      bulk_import: import,
      entity: entity,
      current_user: user
    )
  end

  subject { described_class.new(context: context) }

  describe '#map' do
    context 'when value for specified key exists' do
      it 'returns a map of source & destination user ids from redis' do
        allow(Gitlab::Cache::Import::Caching).to receive(:values_from_hash).and_return({ "1" => "2" })

        expect(subject.map).to eq({ 1 => 2 })
      end
    end

    context 'when value for specified key does not exist' do
      it 'returns default value' do
        expect(subject.map[:non_existent_key]).to eq(user.id)
      end
    end
  end

  describe '#map_usernames' do
    context 'when value for specified key exists' do
      it 'returns a map of source & destination usernames from redis' do
        allow(Gitlab::Cache::Import::Caching).to receive(:values_from_hash).and_return({ "source_username" => "destination_username" })

        expect(subject.map_usernames).to eq({ "source_username" => "destination_username" })
      end
    end

    context 'when value for specified key does not exist' do
      it 'returns nil' do
        expect(subject.map_usernames[:non_existent_key]).to be_nil
      end
    end
  end

  describe '#default_user_id' do
    it 'returns current user id' do
      expect(subject.default_user_id).to eq(user.id)
    end
  end

  describe '#include?' do
    context 'when source user id is present in the map' do
      it 'returns true' do
        allow(subject).to receive(:map).and_return({ 1 => 2 })

        expect(subject.include?(1)).to eq(true)
      end
    end

    context 'when source user id is missing in the map' do
      it 'returns false' do
        allow(subject).to receive(:map).and_return({})

        expect(subject.include?(1)).to eq(false)
      end
    end
  end

  describe '#cache_source_user_id' do
    it 'caches provided source & destination user ids in redis' do
      expect(Gitlab::Cache::Import::Caching).to receive(:hash_add).with("bulk_imports/#{import.id}/#{entity.id}/source_user_ids", 1, 2)

      subject.cache_source_user_id(1, 2)
    end
  end

  describe '#cache_source_username' do
    it 'caches provided source & destination usernames in redis' do
      expect(Gitlab::Cache::Import::Caching).to receive(:hash_add).with("bulk_imports/#{import.id}/#{entity.id}/source_usernames", 'source', 'destination')

      subject.cache_source_username('source', 'destination')
    end
  end
end
