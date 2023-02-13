# frozen_string_literal: true

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
end
