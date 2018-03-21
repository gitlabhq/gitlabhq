require 'spec_helper'

describe Gitlab::CrossProjectAccess::CheckCollection do
  subject(:collection) { described_class.new }

  describe '#add_collection' do
    it 'merges the checks of 2 collections' do
      initial_check = double('check')
      collection.add_check(initial_check)

      other_collection = described_class.new
      other_check = double('other_check')
      other_collection.add_check(other_check)

      shared_check = double('shared check')
      other_collection.add_check(shared_check)
      collection.add_check(shared_check)

      collection.add_collection(other_collection)

      expect(collection.checks).to contain_exactly(initial_check, shared_check, other_check)
    end
  end

  describe '#should_run?' do
    def fake_check(run, skip)
      check = double("Check: run=#{run} - skip={skip}")
      allow(check).to receive(:should_run?).and_return(run)
      allow(check).to receive(:should_skip?).and_return(skip)
      allow(check).to receive(:skip).and_return(skip)

      check
    end

    it 'returns true if one of the check says it should run' do
      check = fake_check(true, false)
      other_check = fake_check(false, false)

      collection.add_check(check)
      collection.add_check(other_check)

      expect(collection.should_run?(double)).to be_truthy
    end

    it 'returns false if one of the check says it should be skipped' do
      check = fake_check(true, false)
      other_check = fake_check(false, true)

      collection.add_check(check)
      collection.add_check(other_check)

      expect(collection.should_run?(double)).to be_falsey
    end
  end
end
