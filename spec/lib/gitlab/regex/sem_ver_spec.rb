# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Regex::SemVer, feature_category: :tooling do
  describe '.optional_prefixed' do
    subject { described_class.optional_prefixed }

    it { is_expected.to match('v1.2.3') }
    it { is_expected.to match('1.2.3') }
    it { is_expected.to match('v1.2.3-beta') }
    it { is_expected.to match('1.2.3-beta') }
    it { is_expected.to match('1.2.3-alpha.3') }
    it { is_expected.to match('v1.2.3-alpha.3') }
    it { is_expected.not_to match('v 1.2.3-alpha.3') }
    it { is_expected.not_to match('V1.2.3') }
    it { is_expected.not_to match('v1') }
    it { is_expected.not_to match('1') }
    it { is_expected.not_to match('1.2') }
    it { is_expected.not_to match('1./2.3') }
  end
end
