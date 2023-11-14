# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::HashedPath do
  let(:root_hash) { 1 }
  let(:hashed_path) { described_class.new(*path, root_hash: root_hash) }

  describe '#to_s' do
    subject { hashed_path }

    context 'when path contains a single value' do
      let(:path) { 'path' }

      it 'returns the disk path' do
        expect(subject).to match(%r[\h{2}/\h{2}/\h{64}/path])
      end
    end

    context 'when path contains multiple values' do
      let(:path) { %w[path1 path2] }

      it 'returns the disk path' do
        expect(subject).to match(%r[\h{2}/\h{2}/\h{64}/path1/path2])
      end
    end
  end
end
