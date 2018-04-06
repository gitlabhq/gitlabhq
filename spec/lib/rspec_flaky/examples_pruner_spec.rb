require 'spec_helper'

describe RspecFlaky::ExamplesPruner, :aggregate_failures do
  let(:collection_hash) do
    {
      a: { example_id: 'spec/foo/bar_spec.rb:2' },
      b: { example_id: 'spec/foo/baz_spec.rb:3', first_flaky_at: Time.utc(2000, 1, 1).to_s, last_flaky_at: Time.utc(2000, 2, 1).to_s }
    }
  end

  describe '#initialize' do
    it 'accepts a collection' do
      expect { described_class.new(RspecFlaky::FlakyExamplesCollection.new(collection_hash)) }.not_to raise_error
    end

    it 'does not accept anything else' do
      expect { described_class.new([1, 2, 3]) }.to raise_error(ArgumentError, "`collection` must be a RspecFlaky::FlakyExamplesCollection, Array given!")
    end
  end

  describe '#prune_examples_older_than' do
    it 'returns a new collection without the examples older than 3 months' do
      collection = RspecFlaky::FlakyExamplesCollection.new(collection_hash)

      new_report = collection.to_report.dup.tap { |r| r.delete(:b) }
      new_collection = described_class.new(collection).prune_examples_older_than(3.months.ago)

      expect(new_collection).to be_a(RspecFlaky::FlakyExamplesCollection)
      expect(new_collection.to_report).to eq(new_report)
      expect(collection).to have_key(:b)
    end
  end
end
