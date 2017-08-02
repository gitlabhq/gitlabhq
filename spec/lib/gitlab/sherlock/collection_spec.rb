require 'spec_helper'

describe Gitlab::Sherlock::Collection do
  let(:collection) { described_class.new }

  let(:transaction) do
    Gitlab::Sherlock::Transaction.new('POST', '/cat_pictures')
  end

  describe '#add' do
    it 'adds a new transaction' do
      collection.add(transaction)

      expect(collection).not_to be_empty
    end

    it 'is aliased as <<' do
      collection << transaction

      expect(collection).not_to be_empty
    end
  end

  describe '#each' do
    it 'iterates over every transaction' do
      collection.add(transaction)

      expect { |b| collection.each(&b) }.to yield_with_args(transaction)
    end
  end

  describe '#clear' do
    it 'removes all transactions' do
      collection.add(transaction)

      collection.clear

      expect(collection).to be_empty
    end
  end

  describe '#empty?' do
    it 'returns true for an empty collection' do
      expect(collection).to be_empty
    end

    it 'returns false for a collection with a transaction' do
      collection.add(transaction)

      expect(collection).not_to be_empty
    end
  end

  describe '#find_transaction' do
    it 'returns the transaction for the given ID' do
      collection.add(transaction)

      expect(collection.find_transaction(transaction.id)).to eq(transaction)
    end

    it 'returns nil when no transaction could be found' do
      collection.add(transaction)

      expect(collection.find_transaction('cats')).to be_nil
    end
  end

  describe '#newest_first' do
    it 'returns transactions sorted from new to old' do
      trans1 = Gitlab::Sherlock::Transaction.new('POST', '/cat_pictures')
      trans2 = Gitlab::Sherlock::Transaction.new('POST', '/more_cat_pictures')

      allow(trans1).to receive(:finished_at).and_return(Time.utc(2015, 1, 1))
      allow(trans2).to receive(:finished_at).and_return(Time.utc(2015, 1, 2))

      collection.add(trans1)
      collection.add(trans2)

      expect(collection.newest_first).to eq([trans2, trans1])
    end
  end
end
