# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/helpers/saas_test_helper'

RSpec.describe Gitlab::Saas, feature_category: :shared do
  include SaasTestHelper

  describe '.root_domain' do
    subject { described_class.root_domain }

    it { is_expected.to eq('gitlab.com') }
  end

  describe '.canary_toggle_com_url' do
    subject { described_class.canary_toggle_com_url }

    it { is_expected.to eq(get_next_url) }
  end

  describe '.promo_host' do
    subject { described_class.promo_host }

    it 'returns the url' do
      is_expected.to eq('about.gitlab.com')
    end
  end

  context 'for methods overridden in EE', unless: Gitlab.ee? do
    describe '.feature_available?' do
      subject { described_class.feature_available?(:some_feature) } # rubocop:disable Gitlab/FeatureAvailableUsage -- we are testing that no error is raised in FOSS here

      it { is_expected.to be(false) }
    end

    describe '.enabled?' do
      subject { described_class.enabled? }

      it { is_expected.to be(false) }
    end

    describe '.feature_file_path' do
      subject { described_class.feature_file_path('some_feature') }

      it { is_expected.to be_nil }
    end
  end
end
