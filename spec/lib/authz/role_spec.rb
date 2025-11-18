# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Role, feature_category: :system_access do
  include RolesHelpers

  describe '.roles_user_can_assign' do
    RolesHelpers.assignable_roles.each do |current_level, expected|
      context "with #{current_level}" do
        it 'returns correct assignable roles' do
          # Use the actual module's constants directly
          access_level = Gitlab::Access.sym_options_with_owner[current_level]
          result = described_class.roles_user_can_assign(access_level)

          # Get the expected access levels using the module's mappings
          expected_levels = expected.map { |role| access_level_value(role) }

          expect(result.values).to match_array(expected_levels)
        end
      end
    end
  end

  def access_level_value(name)
    Gitlab::Access.sym_options_with_owner[name]
  end
end
