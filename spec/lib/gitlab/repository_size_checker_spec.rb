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
      total_repository_size_excess: 0,
      additional_purchased_storage: 0,
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
    include_examples 'checker size above limit'
    include_examples 'checker size not over limit'
  end

  describe '#exceeded_size' do
    include_examples 'checker size exceeded'
  end
end
