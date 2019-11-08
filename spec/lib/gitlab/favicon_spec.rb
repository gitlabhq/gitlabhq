# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Favicon, :request_store do
  describe '.main' do
    it 'defaults to favicon.png' do
      stub_rails_env('production')
      expect(described_class.main).to match_asset_path '/assets/favicon.png'
    end

    it 'has blue favicon for development', unless: Gitlab.ee? do
      stub_rails_env('development')
      expect(described_class.main).to match_asset_path '/assets/favicon-blue.png'
    end

    it 'has yellow favicon for canary' do
      stub_env('CANARY', 'true')
      expect(described_class.main).to match_asset_path 'favicon-yellow.png'
    end

    it 'uses the custom favicon if a favicon appearance is present' do
      create :appearance, favicon: fixture_file_upload('spec/fixtures/dk.png')
      expect(described_class.main).to match %r{/uploads/-/system/appearance/favicon/\d+/dk.png}
    end

    context 'asset host' do
      before do
        stub_rails_env('production')
      end

      it 'returns a relative url when the asset host is not configured' do
        expect(described_class.main).to match %r{^/assets/favicon-(?:\h+).png$}
      end

      it 'returns a full url when the asset host is configured' do
        allow(ActionController::Base).to receive(:asset_host).and_return('http://assets.local')
        expect(described_class.main).to match %r{^http://localhost/assets/favicon-(?:\h+).png$}
      end
    end
  end

  describe '.status_overlay' do
    subject { described_class.status_overlay('favicon_status_created') }

    it 'returns the overlay for the status' do
      expect(subject).to match_asset_path '/assets/ci_favicons/favicon_status_created.png'
    end
  end

  describe '.available_status_names' do
    subject { described_class.available_status_names }

    it 'returns the available status names' do
      expect(subject).to eq %w(
        favicon_status_canceled
        favicon_status_created
        favicon_status_failed
        favicon_status_manual
        favicon_status_not_found
        favicon_status_pending
        favicon_status_preparing
        favicon_status_running
        favicon_status_scheduled
        favicon_status_skipped
        favicon_status_success
        favicon_status_warning
      )
    end
  end
end
