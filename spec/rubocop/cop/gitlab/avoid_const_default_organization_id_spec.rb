# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_const_default_organization_id'

RSpec.describe RuboCop::Cop::Gitlab::AvoidConstDefaultOrganizationId, feature_category: :organization do
  shared_examples 'raises rubocop offense' do |organization_method|
    it "registers offence for #{organization_method}" do
      expect_offense(<<~RUBY)
      #{organization_method}
      #{'^' * organization_method.length} Avoid using `DEFAULT_ORGANIZATION_ID`. [...]
      RUBY
    end
  end

  it_behaves_like 'raises rubocop offense', 'Organization::DEFAULT_ORGANIZATION_ID'
  it_behaves_like 'raises rubocop offense', '::Organizations::Organization::DEFAULT_ORGANIZATION_ID'
  it_behaves_like 'raises rubocop offense', 'Organizations::Organization::DEFAULT_ORGANIZATION_ID'
  it_behaves_like 'raises rubocop offense', 'DEFAULT_ORGANIZATION_ID'

  it 'flags class constant' do
    expect_offense(<<~RUBY)
    class SomeClass
      DEFAULT_ORGANIZATION_ID = 1
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using `DEFAULT_ORGANIZATION_ID`. [...]
    end
    RUBY
  end
end
