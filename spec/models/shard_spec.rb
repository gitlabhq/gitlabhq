# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shard do
  describe 'associations' do
    it { is_expected.to have_many(:project_repositories).dependent(:restrict_with_exception) }
  end

  describe 'deletion restriction' do
    it 'cannot be deleted while it has associated project_repositories' do
      shard = create(:shard, name: 'test-storage')
      create(:project_repository, shard: shard)

      expect { shard.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it 'can be deleted when it has no associated project_repositories' do
      shard = create(:shard, name: 'test-storage')

      expect { shard.destroy! }.not_to raise_error
    end
  end

  describe '.populate!' do
    it 'creates shards based on the config file' do
      expect(described_class.all).to be_empty

      stub_storage_settings(foo: {}, bar: {}, baz: {})

      described_class.populate!

      expect(described_class.all.map(&:name)).to match_array(%w[default foo bar baz])
    end
  end

  describe '.by_name' do
    let(:default_shard) { described_class.find_by(name: 'default') }

    before do
      described_class.populate!
    end

    it 'returns an existing shard' do
      expect(described_class.by_name('default')).to eq(default_shard)
    end

    it 'creates a new shard' do
      result = described_class.by_name('foo')

      expect(result).not_to eq(default_shard)
      expect(result.name).to eq('foo')
    end

    it 'returns existing record if creation races' do
      shard_created_by_others = double(described_class)

      expect(described_class)
        .to receive(:find_by)
        .with({ name: 'new_shard' })
        .and_return(nil, shard_created_by_others)

      expect(described_class)
        .to receive(:create)
        .with({ name: 'new_shard' })
        .and_raise(ActiveRecord::RecordNotUnique, 'fail')
        .once

      expect(described_class.by_name('new_shard')).to eq(shard_created_by_others)
    end
  end
end
