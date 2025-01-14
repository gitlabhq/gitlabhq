# frozen_string_literal: true

require 'spec_helper'

# Only specs that *cannot* be run with fast_spec_helper only
# See regex_spec for tests that do not require the full spec_helper
RSpec.describe Gitlab::Regex::Packages::Protection::Rules, feature_category: :tooling do
  describe '.protection_rules_npm_package_name_pattern_regex' do
    subject { described_class.protection_rules_npm_package_name_pattern_regex }

    it_behaves_like 'npm package name regex'

    it { is_expected.to match('@scope/package-*') }
    it { is_expected.to match('@my-scope/*my-package-with-wildcard-inbetween') }
    it { is_expected.to match('@my-scope/*my-package-with-wildcard-start') }
    it { is_expected.to match('@my-scope/my-*package-*with-wildcard-multiple-*') }
    it { is_expected.to match('@my-scope/my-package-with_____underscore') }
    it { is_expected.to match('@my-scope/my-package-with-wildcard-end*') }
    it { is_expected.to match('@my-scope/my-package-with-regex-characters.+') }

    it { is_expected.not_to match('@my-scope/my-package-with-percent-sign-%') }
    it { is_expected.not_to match('*@my-scope/my-package-with-wildcard-start') }
    it { is_expected.not_to match('@my-scope/my-package-with-backslash-\*') }
  end

  describe '.protection_rules_pypi_package_name_pattern_regex' do
    subject { described_class.protection_rules_pypi_package_name_pattern_regex }

    it_behaves_like 'package name regex'

    it { is_expected.to match('@scope/package-*') }
    it { is_expected.to match('@my-scope/*my-package-with-wildcard-inbetween') }
    it { is_expected.to match('@my-scope/*my-package-with-wildcard-start') }
    it { is_expected.to match('@my-scope/my-*package-*with-wildcard-multiple-*') }
    it { is_expected.to match('@my-scope/my-package-with_____underscore') }
    it { is_expected.to match('@my-scope/my-package-with-wildcard-end*') }

    it { is_expected.not_to match('@my-scope/my-package-with-regex-characters.+') }
    it { is_expected.not_to match('@my-scope/my-package-with-percent-sign-%') }
    it { is_expected.not_to match('*@my-scope/my-package-with-wildcard-start') }
    it { is_expected.not_to match('@my-scope/my-package-with-backslash-\*') }
  end
end
