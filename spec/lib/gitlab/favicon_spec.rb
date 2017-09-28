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
      expect(described_class.main).to match %r{/uploads/-/system/appearance/favicon/\d+/favicon_main_dk.ico}
    end
  end

  describe '.status' do
    subject { described_class.status('favicon_status_created') }

    it 'defaults to the stock icon' do
      expect(subject).to eq '/assets/ci_favicons/favicon_status_created.ico'
    end

    it 'uses the custom favicon if a favicon appearance is present' do
      create :appearance, favicon: fixture_file_upload(Rails.root.join('spec/fixtures/dk.png'))
      expect(subject).to match(%r{/uploads/-/system/appearance/favicon/\d+/favicon_status_created_dk.ico})
    end
  end
end
