# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/prevent_organization_first'

RSpec.describe RuboCop::Cop::Gitlab::PreventOrganizationFirst, feature_category: :organization do
  shared_examples 'raises rubocop offense' do |organization_method|
    it "registers offence for #{organization_method}" do
      expect_offense(<<~RUBY)
      #{organization_method}
      #{'^' * organization_method.length} Avoid using `Organizations::Organization.first` or `first!`. [...]
      RUBY
    end
  end

  it_behaves_like 'raises rubocop offense', 'Organization.first'
  it_behaves_like 'raises rubocop offense', '::Organizations::Organization.first'
  it_behaves_like 'raises rubocop offense', 'Organizations::Organization.first'
  it_behaves_like 'raises rubocop offense', 'Organization.first!'
  it_behaves_like 'raises rubocop offense', '::Organizations::Organization.first!'
  it_behaves_like 'raises rubocop offense', 'Organizations::Organization.first!'

  it 'does not raise an offense for other instances with first' do
    expect_no_offenses(<<~RUBY)
      [1, 2, 3].first
      array.first
    RUBY
  end

  it 'does not register an offense when using first on other model classes' do
    expect_no_offenses(<<~RUBY)
      User.first
      Project.first
      Namespace.first!
    RUBY
  end
end
