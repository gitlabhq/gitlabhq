# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::IssuablesCountForState do
  let(:finder) do
    double(:finder, current_user: nil, params: {}, count_by_state: { opened: 2, closed: 1 })
  end

  let(:project) { nil }
  let(:fast_fail) { nil }
  let(:counter) { described_class.new(finder, project, fast_fail: fast_fail) }

  describe 'project given' do
    let(:project) { build(:project) }

    it 'provides the project' do
      expect(counter.project).to eq(project)
    end
  end

  describe '.declarative_policy_class' do
    subject { described_class.declarative_policy_class }

    it { is_expected.to eq('IssuablePolicy') }
  end

  describe '#for_state_or_opened' do
    it 'returns the number of issuables for the given state' do
      expect(counter.for_state_or_opened(:closed)).to eq(1)
    end

    it 'returns the number of open issuables when no state is given' do
      expect(counter.for_state_or_opened).to eq(2)
    end

    it 'returns the number of open issuables when a nil value is given' do
      expect(counter.for_state_or_opened(nil)).to eq(2)
    end
  end

  describe '#[]' do
    it 'returns the number of issuables for the given state' do
      expect(counter[:closed]).to eq(1)
    end

    it 'casts valid states from Strings to Symbols' do
      expect(counter['closed']).to eq(1)
    end

    it 'returns 0 when using an invalid state name as a String' do
      expect(counter['kittens']).to be_zero
    end

    context 'fast_fail enabled' do
      let(:fast_fail) { true }

      it 'returns the expected value' do
        expect(counter[:closed]).to eq(1)
      end

      it 'returns -1 when the database times out' do
        expect(finder).to receive(:count_by_state).and_raise(ActiveRecord::QueryCanceled)

        expect(counter[:closed]).to eq(-1)
      end
    end
  end
end
