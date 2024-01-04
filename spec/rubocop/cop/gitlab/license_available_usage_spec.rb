# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/gitlab/license_available_usage'

RSpec.describe RuboCop::Cop::Gitlab::LicenseAvailableUsage, feature_category: :shared do
  let(:msg) { described_class::MSG }

  describe 'uses license check' do
    it 'registers an offense' do
      expect_offense(<<~SOURCE)
        License.feature_available?(:elastic_search) && super
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid License.feature_available? usage in ApplicationSetting due to possible cyclical dependency issue. For more information see: https://gitlab.com/gitlab-org/gitlab/-/issues/423237
      SOURCE
    end
  end

  describe 'no license check' do
    let(:source) do
      <<~RUBY
        class C
          def check_without_license_usage?
            test?(:feature)
          end
        end
      RUBY
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end
end
