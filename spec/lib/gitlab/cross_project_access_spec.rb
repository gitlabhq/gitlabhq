require 'spec_helper'

describe Gitlab::CrossProjectAccess do
  let(:super_class) { Class.new }
  let(:descendant_class) { Class.new(super_class) }
  let(:current_instance) { described_class.new }

  before do
    allow(described_class).to receive(:instance).and_return(current_instance)
  end

  describe '#add_check' do
    it 'keeps track of the properties to check' do
      expect do
        described_class.add_check(super_class,
                                  actions: { index: true },
                                  positive_condition: -> { true },
                                  negative_condition: -> { false })
      end.to change { described_class.checks.size }.by(1)
    end

    it 'builds the check correctly' do
      check_collection = described_class.add_check(super_class,
                                                   actions: { index: true },
                                                   positive_condition: -> { 'positive' },
                                                   negative_condition: -> { 'negative' })

      check = check_collection.checks.first

      expect(check.actions).to eq(index: true)
      expect(check.positive_condition.call).to eq('positive')
      expect(check.negative_condition.call).to eq('negative')
    end

    it 'merges the checks of a parent class into existing checks of a subclass' do
      subclass_collection = described_class.add_check(descendant_class)

      expect(subclass_collection).to receive(:add_collection).and_call_original

      described_class.add_check(super_class)
    end

    it 'merges the existing checks of a superclass into the checks of a subclass' do
      super_collection = described_class.add_check(super_class)
      descendant_collection = described_class.add_check(descendant_class)

      expect(descendant_collection.checks).to include(*super_collection.checks)
    end
  end

  describe '#find_check' do
    it 'returns a check when it was defined for a superclass' do
      expected_check = described_class.add_check(super_class,
                                                 actions: { index: true },
                                                 positive_condition: -> { 'positive' },
                                                 negative_condition: -> { 'negative' })

      expect(described_class.find_check(descendant_class.new))
        .to eq(expected_check)
    end

    it 'caches the result for a subclass' do
      described_class.add_check(super_class,
                                actions: { index: true },
                                positive_condition: -> { 'positive' },
                                negative_condition: -> { 'negative' })

      expect(described_class.instance).to receive(:closest_parent).once.and_call_original

      2.times { described_class.find_check(descendant_class.new) }
    end

    it 'returns the checks for the closest class if there are more checks available' do
      described_class.add_check(super_class,
                                actions: { index: true })
      expected_check = described_class.add_check(descendant_class,
                                                 actions: { index: true, show: false })

      check = described_class.find_check(descendant_class.new)

      expect(check).to eq(expected_check)
    end
  end
end
