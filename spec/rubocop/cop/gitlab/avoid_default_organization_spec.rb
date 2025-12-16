# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_default_organization'

RSpec.describe RuboCop::Cop::Gitlab::AvoidDefaultOrganization, feature_category: :organization do
  shared_examples 'raises rubocop offense' do |organization_method|
    it "registers offence for #{organization_method}" do
      expect_offense(<<~RUBY)
      #{organization_method}
      #{'^' * organization_method.length} Avoid using `Organizations::Organization.default_organization`. [...]
      RUBY
    end
  end

  it_behaves_like 'raises rubocop offense', 'Organization.default_organization'
  it_behaves_like 'raises rubocop offense', '::Organizations::Organization.default_organization'
  it_behaves_like 'raises rubocop offense', 'Organizations::Organization.default_organization'

  it 'does not raise an offense for other models using #default_organization' do
    expect_no_offenses(<<~RUBY)
      RandomModel.default_organization
    RUBY
  end
end
