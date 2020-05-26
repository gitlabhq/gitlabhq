# frozen_string_literal: true

require 'spec_helper'

describe Ci::InstanceVariable do
  subject { build(:ci_instance_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to include_module(Ci::Maskable) }
  it { is_expected.to validate_uniqueness_of(:key).with_message(/\(\w+\) has already been taken/) }
  it { is_expected.to validate_length_of(:encrypted_value).is_at_most(1024).with_message(/Variables over 700 characters risk exceeding the limit/) }

  describe '.unprotected' do
    subject { described_class.unprotected }

    context 'when variable is protected' do
      before do
        create(:ci_instance_variable, :protected)
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when variable is not protected' do
      let(:variable) { create(:ci_instance_variable, protected: false) }

      it 'returns the variable' do
        is_expected.to contain_exactly(variable)
      end
    end
  end

  describe '.all_cached', :use_clean_rails_memory_store_caching do
    let_it_be(:unprotected_variable) { create(:ci_instance_variable, protected: false) }
    let_it_be(:protected_variable) { create(:ci_instance_variable, protected: true) }

    it { expect(described_class.all_cached).to contain_exactly(protected_variable, unprotected_variable) }

    it 'memoizes the result' do
      expect(described_class).to receive(:unscoped).once.and_call_original

      2.times do
        expect(described_class.all_cached).to contain_exactly(protected_variable, unprotected_variable)
      end
    end

    it 'removes scopes' do
      expect(described_class.unprotected.all_cached).to contain_exactly(protected_variable, unprotected_variable)
    end

    it 'resets the cache when records are deleted' do
      expect(described_class.all_cached).to contain_exactly(protected_variable, unprotected_variable)

      protected_variable.destroy

      expect(described_class.all_cached).to contain_exactly(unprotected_variable)
    end

    it 'resets the cache when records are inserted' do
      expect(described_class.all_cached).to contain_exactly(protected_variable, unprotected_variable)

      variable = create(:ci_instance_variable, protected: true)

      expect(described_class.all_cached).to contain_exactly(protected_variable, unprotected_variable, variable)
    end
  end

  describe '.unprotected_cached', :use_clean_rails_memory_store_caching do
    let_it_be(:unprotected_variable) { create(:ci_instance_variable, protected: false) }
    let_it_be(:protected_variable) { create(:ci_instance_variable, protected: true) }

    it { expect(described_class.unprotected_cached).to contain_exactly(unprotected_variable) }

    it 'memoizes the result' do
      expect(described_class).to receive(:unscoped).once.and_call_original

      2.times do
        expect(described_class.unprotected_cached).to contain_exactly(unprotected_variable)
      end
    end
  end
end
