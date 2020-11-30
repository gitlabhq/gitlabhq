# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
  describe '#whats_new_storage_key' do
    subject { helper.whats_new_storage_key }

    context 'when version exist' do
      let(:release_item) { double(:item) }

      before do
        allow(ReleaseHighlight).to receive(:most_recent_version).and_return(84.0)
      end

      it { is_expected.to eq('display-whats-new-notification-84.0') }
    end

    context 'when most recent release highlights do NOT exist' do
      before do
        allow(ReleaseHighlight).to receive(:most_recent_version).and_return(nil)
      end

      it { is_expected.to be_nil }
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
