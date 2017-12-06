require 'rails_helper'

RSpec.describe Gitlab::Favicon, :request_store do
  describe '.main' do
    it 'defaults to favicon.ico' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      expect(described_class.main).to eq 'favicon.ico'
    end

    it 'has blue favicon for development' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      expect(described_class.main).to eq 'favicon-blue.ico'
    end

    it 'has yellow favicon for canary' do
      stub_env('CANARY', 'true')
      expect(described_class.main).to eq 'favicon-yellow.ico'
    end

    it 'uses the custom favicon if a favicon appearance is present' do
      create :appearance, favicon: fixture_file_upload(Rails.root.join('spec/fixtures/dk.png'))
      expect(described_class.main).to match %r{/uploads/-/system/appearance/favicon/\d+/favicon_main_dk.png}
    end
  end

  describe '.status_overlay' do
    subject { described_class.status_overlay('favicon_status_created') }

    it 'returns the overlay for the status' do
      expect(subject).to eq '/assets/ci_favicons/overlays/favicon_status_created.png'
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
