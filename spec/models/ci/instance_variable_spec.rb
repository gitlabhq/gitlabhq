# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InstanceVariable do
  subject { build(:ci_instance_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to include_module(Ci::Maskable) }
  it { is_expected.to validate_uniqueness_of(:key).with_message(/\(\w+\) has already been taken/) }
  it { is_expected.to validate_length_of(:value).is_at_most(10_000).with_message(/The value of the provided variable exceeds the 10000 character limit/) }

  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_instance_variable) }
  end

  describe '#value' do
    context 'without application limit' do
      # Ensures breakage if encryption algorithm changes
      let(:variable) { build(:ci_instance_variable, key: 'too_long', value: value) }

      before do
        allow(variable).to receive(:valid?).and_return(true)
      end

      context 'when value is over the limit' do
        let(:value) { SecureRandom.alphanumeric(10_002) }

        it 'raises a database level error' do
          expect { variable.save! }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end

      context 'when value is under the limit' do
        let(:value) { SecureRandom.alphanumeric(10_000) }

        it 'does not raise database level error' do
          expect { variable.save! }.not_to raise_error
        end
      end
    end
  end

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

      protected_variable.destroy!

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

  describe "description" do
    it { is_expected.to allow_values('').for(:description) }
    it { is_expected.to allow_values(nil).for(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
  end
end
