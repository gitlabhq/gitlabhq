# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'countries', feature_category: :onboarding do
  it 'configures locals to EN' do
    expect(ISO3166.configuration.locales).to eq([:en])
  end

  it 'initialises Ukraine with custom country name' do
    expect(ISO3166::Country['UA'].data["name"]).to be('Ukraine (except the Crimea, Donetsk, and Luhansk regions)')
  end

  it 'initialises Taiwan with custom country name' do
    expect(ISO3166::Country['TW'].data["name"]).to be('Taiwan')
  end

  describe 'Kosovo registration' do
    it 'registers Kosovo as a country' do
      kosovo = ISO3166::Country['XK']

      expect(kosovo).not_to be_nil
      expect(kosovo.data['name']).to eq('Kosovo')
      expect(kosovo.data['alpha2']).to eq('XK')
      expect(kosovo.data['alpha3']).to eq('XKX')
      expect(kosovo.data['country_code']).to eq('383')
      expect(kosovo.data['continent']).to eq('EU')
      expect(kosovo.data['region']).to eq('Southern Europe')
    end
  end
end
