# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
  describe '#whats_new_storage_key' do
    subject { helper.whats_new_storage_key }

    before do
      allow(helper).to receive(:whats_new_most_recent_release_items).and_return(json)
    end

    context 'when recent release items exist' do
      let(:json) { [{ release: 84.0 }].to_json }

      it { is_expected.to eq('display-whats-new-notification-84.0') }

      context 'when the release items are missing the release key' do
        let(:json) { [{ title: 'bells!' }].to_json }

        it { is_expected.to eq('display-whats-new-notification') }
      end
    end

    context 'when recent release items do NOT exist' do
      let(:json) { WhatsNewHelper::EMPTY_JSON }

      it { is_expected.to be_nil }
    end
  end

  describe '#whats_new_most_recent_release_items_count' do
    subject { helper.whats_new_most_recent_release_items_count }

    before do
      allow(helper).to receive(:whats_new_most_recent_release_items).and_return(json)
    end

    context 'when recent release items exist' do
      let(:json) { [:bells, :and, :whistles].to_json }

      it { is_expected.to eq(3) }
    end

    context 'when recent release items do NOT exist' do
      let(:json) { WhatsNewHelper::EMPTY_JSON }

      it { is_expected.to be_nil }
    end
  end

  describe '#whats_new_most_recent_release_items' do
    let(:fixture_dir_glob) { Dir.glob(File.join('spec', 'fixtures', 'whats_new', '*.yml')) }

    it 'returns json from the most recent file' do
      allow(Dir).to receive(:glob).with(Rails.root.join('data', 'whats_new', '*.yml')).and_return(fixture_dir_glob)

      expect(helper.whats_new_most_recent_release_items).to include({ title: "bright and sunshinin' day" }.to_json)
    end

    it 'fails gracefully and logs an error' do
      allow(YAML).to receive(:load_file).and_raise

      expect(Gitlab::ErrorTracking).to receive(:track_exception)
      expect(helper.whats_new_most_recent_release_items).to eq(''.to_json)
    end
  end
end
