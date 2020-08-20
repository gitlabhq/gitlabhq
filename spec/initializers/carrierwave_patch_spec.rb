# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CarrierWave::Storage::Fog::File' do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:storage) { CarrierWave::Storage::Fog.new(uploader) }
  let(:azure_options) do
    {
      azure_storage_account_name: 'AZURE_ACCOUNT_NAME',
      azure_storage_access_key: 'AZURE_ACCESS_KEY',
      provider: 'AzureRM'
    }
  end

  subject { CarrierWave::Storage::Fog::File.new(uploader, storage, 'test') }

  before do
    require 'fog/azurerm'
    allow(uploader).to receive(:fog_credentials).and_return(azure_options)
    Fog.mock!
  end

  describe '#authenticated_url' do
    context 'with Azure' do
      it 'has an authenticated URL' do
        expect(subject.authenticated_url).to eq("https://sa.blob.core.windows.net/test_container/test_blob?token")
      end
    end
  end
end
