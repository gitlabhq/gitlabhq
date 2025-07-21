# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Promo site URLs', 'about', feature_category: :shared do
  describe 'promo_url' do
    subject { promo_url }

    it { is_expected.to eq('https://about.gitlab.com') }

    context 'with query parameters' do
      subject { promo_url(query: { utm_source: 'gitlab', utm_medium: 'web' }) }

      it { is_expected.to eq('https://about.gitlab.com?utm_source=gitlab&utm_medium=web') }
    end

    context 'with path' do
      subject { promo_url(path: '/features') }

      it { is_expected.to eq('https://about.gitlab.com/features') }
    end

    context 'with anchor' do
      subject { promo_url(anchor: 'section1') }

      it { is_expected.to eq('https://about.gitlab.com#section1') }
    end

    context 'with all options' do
      subject { promo_url(path: '/solutions', query: { ref: 'navbar' }, anchor: 'devops') }

      it { is_expected.to eq('https://about.gitlab.com/solutions?ref=navbar#devops') }
    end
  end

  describe 'promo_pricing_url' do
    subject { promo_pricing_url }

    it { is_expected.to eq('https://about.gitlab.com/pricing') }

    context 'with additional path' do
      subject { promo_pricing_url(path: '/saas') }

      it { is_expected.to eq('https://about.gitlab.com/pricing/saas') }
    end

    context 'with query parameters' do
      subject { promo_pricing_url(query: { plan: 'premium' }) }

      it { is_expected.to eq('https://about.gitlab.com/pricing?plan=premium') }
    end

    context 'with anchor' do
      subject { promo_pricing_url(anchor: 'features') }

      it { is_expected.to eq('https://about.gitlab.com/pricing#features') }
    end

    context 'with all options' do
      subject { promo_pricing_url(path: '/enterprise', query: { trial: 'true' }, anchor: 'contact') }

      it { is_expected.to eq('https://about.gitlab.com/pricing/enterprise?trial=true#contact') }
    end
  end
end
