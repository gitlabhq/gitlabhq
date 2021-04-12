# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
  describe '#whats_new_version_digest' do
    let(:digest) { 'digest' }

    it 'calls ReleaseHighlight.most_recent_version_digest' do
      expect(ReleaseHighlight).to receive(:most_recent_version_digest).and_return(digest)

      expect(helper.whats_new_version_digest).to eq(digest)
    end
  end

  describe '#whats_new_most_recent_release_items_count' do
    subject { helper.whats_new_most_recent_release_items_count }

    context 'when recent release items exist' do
      it 'returns the count from the most recent file' do
        allow(ReleaseHighlight).to receive(:most_recent_item_count).and_return(1)

        expect(subject).to eq(1)
      end
    end

    context 'when recent release items do NOT exist' do
      it 'returns nil' do
        allow(ReleaseHighlight).to receive(:most_recent_item_count).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end
end
