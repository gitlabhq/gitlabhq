# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Role, feature_category: :system_access do
  assignable_roles = {
    owner: [:owner, :maintainer, :planner, :developer, :reporter, :guest],
    maintainer: [:maintainer, :developer, :reporter, :guest],
    developer: [:developer, :reporter, :guest],
    reporter: [:reporter, :guest],
    planner: [:planner, :guest],
    guest: [:guest]
  }

  describe '.access_level_encompasses?' do
    def access_level_encompasses?(current_level, level_to_assign)
      described_class.access_level_encompasses?(
        current_access_level: access_level_value(current_level),
        level_to_assign: access_level_value(level_to_assign)
      )
    end

    assignable_roles.each do |current_level, expected|
      context "with #{current_level}" do
        not_expected = Gitlab::Access.sym_options_with_owner.keys - expected

        expected.each do |level_to_assign|
          it "encompasses #{level_to_assign}" do
            expect(access_level_encompasses?(current_level, level_to_assign)).to be(true)
          end
        end

        not_expected.each do |level_to_assign|
          it "does not encompass #{level_to_assign}" do
            expect(access_level_encompasses?(current_level, level_to_assign)).to be(false)
          end
        end
      end
    end

    it 'returns false when current_access_level is nil' do
      result = described_class.access_level_encompasses?(
        current_access_level: nil,
        level_to_assign: Gitlab::Access::MAINTAINER
      )
      expect(result).to be(false)
    end
  end

  describe '.roles_user_can_assign' do
    assignable_roles.each do |current_level, expected|
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
