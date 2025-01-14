# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::VisitorLocation, feature_category: :system_access do
  let(:country_code) { 'DE' }
  let(:country) { 'Germany' }
  let(:city) { 'Frankfurt' }
  let(:headers) { { "Cf-Ipcountry" => country_code, "Cf-Ipcity" => city } }
  let(:request) { instance_double(ActionDispatch::Request, headers: headers) }

  subject(:request_info) { described_class.new(request) }

  it 'returns country and city' do
    expect(request_info.country).to eq(country)
    expect(request_info.city).to eq(city)
  end

  context 'when country code not recognized' do
    let(:country_code) { 'UNKNOWN' }

    it 'returns country code' do
      expect(request_info.country).to eq(country_code)
    end
  end

  context 'when locale is not default' do
    around do |example|
      Gitlab::I18n.with_locale(:de, &example)
    end

    it 'returns localized country name' do
      expect(request_info.country).to eq('Deutschland')
    end
  end

  # Rescue I18nData::NoTranslationAvailable
  context 'when I18n locale is not valid for I18nData locales' do
    around do |example|
      Gitlab::I18n.with_locale(:nl_NL, &example)
    end

    it 'returns English country name by default' do
      expect(request_info.country).to eq('Germany')
    end

    context 'when country code not recognized' do
      let(:country_code) { 'UNKNOWN' }

      it 'returns country code' do
        expect(request_info.country).to eq(country_code)
      end
    end
  end

  context 'when location headers are not set' do
    let(:headers) { {} }

    it 'cannot determine country and city' do
      expect(request_info.country).to be_nil
      expect(request_info.city).to be_nil
    end
  end
end
