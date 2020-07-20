# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositorySizeChecker do
  let(:current_size) { 0 }
  let(:limit) { 50 }
  let(:enabled) { true }

  subject do
    described_class.new(
      current_size_proc: -> { current_size },
      limit: limit,
      enabled: enabled
    )
  end

  describe '#enabled?' do
    context 'when enabled' do
      it 'returns true' do
        expect(subject.enabled?).to be_truthy
      end
    end

    context 'when limit is zero' do
      let(:limit) { 0 }

      it 'returns false' do
        expect(subject.enabled?).to be_falsey
      end
    end
  end

  describe '#changes_will_exceed_size_limit?' do
    let(:current_size) { 49 }

    it 'returns true when changes go over' do
      expect(subject.changes_will_exceed_size_limit?(2)).to be_truthy
    end

    it 'returns false when changes do not go over' do
      expect(subject.changes_will_exceed_size_limit?(1)).to be_falsey
    end
  end

  describe '#above_size_limit?' do
    context 'when size is above the limit' do
      let(:current_size) { 100 }

      it 'returns true' do
        expect(subject.above_size_limit?).to be_truthy
      end
    end

    it 'returns false when not over the limit' do
      expect(subject.above_size_limit?).to be_falsey
    end
  end

  describe '#exceeded_size' do
    context 'when current size is below or equal to the limit' do
      let(:current_size) { 50 }

      it 'returns zero' do
        expect(subject.exceeded_size).to eq(0)
      end
    end

    context 'when current size is over the limit' do
      let(:current_size) { 51 }

      it 'returns zero' do
        expect(subject.exceeded_size).to eq(1)
      end
    end

    context 'when change size will be over the limit' do
      let(:current_size) { 50 }

      it 'returns zero' do
        expect(subject.exceeded_size(1)).to eq(1)
      end
    end

    context 'when change size will not be over the limit' do
      let(:current_size) { 49 }

      it 'returns zero' do
        expect(subject.exceeded_size(1)).to eq(0)
      end
    end
  end
end
