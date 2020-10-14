# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
  describe '#whats_new_storage_key' do
    subject { helper.whats_new_storage_key }

    before do
      allow(helper).to receive(:whats_new_most_recent_version).and_return(version)
    end

    context 'when version exist' do
      let(:version) { '84.0' }

      it { is_expected.to eq('display-whats-new-notification-84.0') }
    end

    context 'when recent release items do NOT exist' do
      let(:version) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#whats_new_most_recent_release_items_count' do
    subject { helper.whats_new_most_recent_release_items_count }

    context 'when recent release items exist' do
      let(:fixture_dir_glob) { Dir.glob(File.join('spec', 'fixtures', 'whats_new', '*.yml')) }

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
end
