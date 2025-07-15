# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'About site URLs', 'about', feature_category: :shared do
  describe 'about_url' do
    subject { about_url }

    context 'when STAGING_CUSTOMER_PORTAL_URL is unset' do
      it { is_expected.to eq('https://about.gitlab.com') }
    end
  end
end
