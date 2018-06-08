require 'rails_helper'

RSpec.describe Gitlab::Favicon, :request_store do
  describe '.main' do
    it 'defaults to favicon.png' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      expect(described_class.main).to match_asset_path '/assets/favicon.png'
    end

    it 'has green favicon for development' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      expect(described_class.main).to match_asset_path 'favicon-green.png'
    end

    it 'has yellow favicon for canary' do
      stub_env('CANARY', 'true')
      expect(described_class.main).to match_asset_path 'favicon-yellow.png'
    end

    it 'uses the custom favicon if a favicon appearance is present' do
      create :appearance, favicon: fixture_file_upload(Rails.root.join('spec/fixtures/dk.png'))
      expect(described_class.main).to match %r{/uploads/-/system/appearance/favicon/\d+/favicon_main_dk.png}
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
        favicon_status_running
        favicon_status_skipped
        favicon_status_success
        favicon_status_warning
      )
    end
  end
end
