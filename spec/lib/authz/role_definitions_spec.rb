# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Role, feature_category: :permissions do
  # Clear the role definition cache before and after each test to prevent
  # test pollution from cached state that could be affected by BASE_PATH stubs
  # or other modifications to the role definitions
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe 'developer role' do
    it 'includes all job update abilities defined in Ci::JobAbilities' do
      developer_permissions = described_class.get(:developer).permissions(:project)
      missing = ProjectPolicy.all_job_update_abilities.reject { |perm| developer_permissions.include?(perm) }

      expect(missing).to be_empty,
        "Developer role YAML is missing job update abilities: #{missing.join(', ')}. " \
          "Update config/authz/roles/developer.yml to include them."
    end
  end
end
