# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'diffs for streaming' do
  context 'when block is given' do
    let(:expected_block) { proc {} }

    it 'calls diffs_by_changed_paths with given offset' do
      expect(repository).to receive(:diffs_by_changed_paths).with(resource.diff_refs, 0) do |_, &block|
        expect(block).to be(expected_block)
      end

      resource.diffs_for_streaming(&expected_block)
    end

    context 'when offset_index is given' do
      let(:offset) { 5 }

      it 'calls diffs_by_changed_paths with given offset' do
        expect(repository).to receive(:diffs_by_changed_paths).with(resource.diff_refs, offset) do |_, &block|
          expect(block).to be(expected_block)
        end

        resource.diffs_for_streaming({ offset_index: offset }, &expected_block)
      end
    end
  end
end
