# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositorySizeChecker do
  let_it_be(:namespace) { nil }

  let(:current_size) { 0 }
  let(:limit) { 50 }
  let(:enabled) { true }

  subject do
    described_class.new(
      current_size_proc: -> { current_size.megabytes },
      limit: limit.megabytes,
      namespace: namespace,
      enabled: enabled
    )
  end

  describe '#enabled?' do
    context 'when enabled' do
      it 'returns true' do
        expect(subject.enabled?).to eq(true)
      end
    end

    context 'when limit is zero' do
      let(:limit) { 0 }

      it 'returns false' do
        expect(subject.enabled?).to eq(false)
      end
    end
  end

  describe '#changes_will_exceed_size_limit?' do
    let(:current_size) { 49 }
    let(:project) { double }

    it 'returns true when changes go over' do
      expect(subject.changes_will_exceed_size_limit?(2.megabytes, project)).to eq(true)
    end

    it 'returns false when changes do not go over' do
      expect(subject.changes_will_exceed_size_limit?(1.megabytes, project)).to eq(false)
    end
  end

  describe '#above_size_limit?' do
    include_examples 'checker size above limit'
    include_examples 'checker size not over limit'
  end

  describe '#exceeded_size' do
    include_examples 'checker size exceeded'
  end

  describe '#additional_repo_storage_available?' do
    it 'returns false' do
      expect(subject.additional_repo_storage_available?).to eq(false)
    end
  end
end
