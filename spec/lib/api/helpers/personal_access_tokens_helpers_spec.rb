# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PersonalAccessTokensHelpers, feature_category: :system_access do
  # Eight API classes reach granular_scopes_options_for only through this module.
  it 'includes the granular scopes helpers' do
    expect(described_class.ancestors).to include(API::Helpers::Authz::GranularScopesHelpers)
  end
end
