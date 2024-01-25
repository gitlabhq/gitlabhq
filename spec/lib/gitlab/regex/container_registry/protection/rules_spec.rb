# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../../../lib/gitlab/regex'
require_relative '../../../../../support/shared_examples/lib/gitlab/regex_shared_examples'

# All specs that can be run with fast_spec_helper only
# See regex_requires_app_spec for tests that require the full spec_helper
RSpec.describe Gitlab::Regex::ContainerRegistry::Protection::Rules, feature_category: :tooling do
  describe '.protection_rules_container_repository_path_pattern_regex' do
    subject { described_class.protection_rules_container_repository_path_pattern_regex }

    it_behaves_like 'container repository name regex'

    it { is_expected.to match('my/awesome/*image-with-wildcard-inbetween') }
    it { is_expected.to match('my/awesome/*image-with-wildcard-start') }
    it { is_expected.to match('my/awesome/*image-*with-wildcard-multiple-*') }
    it { is_expected.to match('my/awesome/image-with__underscore') }
    it { is_expected.to match('my/awesome/image-with-wildcard-end*') }

    it { is_expected.to match('my/awesome/image-with-container-seperator-period-and-wildcard-end.*') }
    it { is_expected.to match('my/awesome/image-with-container-seperator-slash-and-wildcard-end/*') }
    it { is_expected.to match('my/awesome/image-with-container-seperator-underscore-and-wildcard-end_*') }
    it { is_expected.to match('my/awesome/image-with-container-seperator-underscore-double-and-wildcard-end__*') }

    it { is_expected.not_to match('my/awesome/image-with-whitespace /sub-image') }
    it { is_expected.not_to match('my/awesome/image-with-whitespace /sub-image-with-wildcard-*') }
    it { is_expected.not_to match('my/awesome/image-with-percent-sign-end-%') }
    it { is_expected.not_to match('my/awesome/image-with-percent-sign-and-wildcard-end-%*') }
    it { is_expected.not_to match('*my/awesome/image-with-wildcard-start') }
    it { is_expected.not_to match('my/awesome/image-with-backslash-\*') }
    it { is_expected.not_to match('my/awesome/image-with-UPPERCASE-LETTERS') }
  end
end
