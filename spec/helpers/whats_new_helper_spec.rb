# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WhatsNewHelper do
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
