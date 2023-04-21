# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::LinkPresenter do
  describe '#direct_asset_url' do
    let_it_be(:release) { create(:release) }

    let(:link) { build(:release_link, release: release, url: url, filepath: filepath) }
    let(:url) { 'https://google.com/-/jobs/140463678/artifacts/download' }
    let(:presenter) { described_class.new(link) }

    subject { presenter.direct_asset_url }

    context 'when filepath is provided' do
      let(:filepath) { '/bin/bigfile.exe' }
      let(:expected_url) do
        "http://localhost/#{release.project.full_path}" \
        "/-/releases/#{release.tag}/downloads/bin/bigfile.exe"
      end

      it { is_expected.to eq(expected_url) }
    end

    context 'when filepath is not provided' do
      let(:filepath) { nil }

      it { is_expected.to eq(url) }
    end
  end
end
