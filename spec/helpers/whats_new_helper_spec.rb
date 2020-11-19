# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
  let(:fixture_dir_glob) { Dir.glob(File.join('spec', 'fixtures', 'whats_new', '*.yml')) }

  describe '#whats_new_storage_key' do
    subject { helper.whats_new_storage_key }

    context 'when version exist' do
      before do
        allow(Dir).to receive(:glob).with(Rails.root.join('data', 'whats_new', '*.yml')).and_return(fixture_dir_glob)
      end

      it { is_expected.to eq('display-whats-new-notification-01.05') }
    end

    context 'when recent release items do NOT exist' do
      before do
        allow(helper).to receive(:whats_new_release_items).and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#whats_new_most_recent_release_items_count' do
    subject { helper.whats_new_most_recent_release_items_count }

    context 'when recent release items exist' do
      it 'returns the count from the most recent file' do
        expect(Dir).to receive(:glob).with(Rails.root.join('data', 'whats_new', '*.yml')).and_return(fixture_dir_glob)

        expect(subject).to eq(1)
      end
    end

    context 'when recent release items do NOT exist' do
      before do
        allow(YAML).to receive(:safe_load).and_raise

        expect(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'fails gracefully and logs an error' do
        expect(subject).to be_nil
      end
    end
  end

  # Testing this important private method here because the request spec required multiple confusing mocks and felt wrong and overcomplicated
  describe '#whats_new_items_cache_key' do
    it 'returns a key containing the most recent file name and page parameter' do
      allow(Dir).to receive(:glob).with(Rails.root.join('data', 'whats_new', '*.yml')).and_return(fixture_dir_glob)

      expect(helper.send(:whats_new_items_cache_key, 2)).to eq('whats_new:release_items:file-20201225_01_05:page-2')
    end
  end
end
