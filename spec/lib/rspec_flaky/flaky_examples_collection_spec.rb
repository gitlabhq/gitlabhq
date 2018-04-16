require 'spec_helper'

describe RspecFlaky::FlakyExamplesCollection, :aggregate_failures do
  let(:collection_hash) do
    {
      a: { example_id: 'spec/foo/bar_spec.rb:2' },
      b: { example_id: 'spec/foo/baz_spec.rb:3' }
    }
  end
  let(:collection_report) do
    {
      a: {
        example_id: 'spec/foo/bar_spec.rb:2',
        first_flaky_at: nil,
        last_flaky_at: nil,
        last_flaky_job: nil
      },
      b: {
        example_id: 'spec/foo/baz_spec.rb:3',
        first_flaky_at: nil,
        last_flaky_at: nil,
        last_flaky_job: nil
      }
    }
  end

  describe '#initialize' do
    it 'accepts no argument' do
      expect { described_class.new }.not_to raise_error
    end

    it 'accepts a hash' do
      expect { described_class.new(collection_hash) }.not_to raise_error
    end

    it 'does not accept anything else' do
      expect { described_class.new([1, 2, 3]) }.to raise_error(ArgumentError, "`collection` must be a Hash, Array given!")
    end
  end

  describe '#to_h' do
    it 'calls #to_h on the values' do
      collection = described_class.new(collection_hash)

      expect(collection.to_h).to eq(collection_report)
    end
  end

  describe '#-' do
    it 'returns only examples that are not present in the given collection' do
      collection1 = described_class.new(collection_hash)
      collection2 = described_class.new(
        a: { example_id: 'spec/foo/bar_spec.rb:2' },
        c: { example_id: 'spec/bar/baz_spec.rb:4' })

      expect((collection2 - collection1).to_h).to eq(
        c: {
          example_id: 'spec/bar/baz_spec.rb:4',
          first_flaky_at: nil,
          last_flaky_at: nil,
          last_flaky_job: nil
        })
    end

    it 'fails if the given collection does not respond to `#key?`' do
      collection = described_class.new(collection_hash)

      expect { collection - [1, 2, 3] }.to raise_error(ArgumentError, "`other` must respond to `#key?`, Array does not!")
    end
  end
end
