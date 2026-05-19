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

  describe 'public_anonymous role' do
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:public_group) { create(:group, :public) }

    let(:role) { described_class.get(:public_anonymous) }

    before do
      next unless Gitlab.ee?

      stub_licensed_features(GitlabSubscriptions::Features::ALL_FEATURES.index_with(true))
    end

    it 'lists only project permissions an anonymous caller can exercise on a public project' do
      drift = role.permissions(:project).reject do |permission|
        ::Users::Anonymous.can?(permission, public_project)
      end

      expect(drift).to be_empty,
        "config/authz/roles/public_anonymous.yml lists project permissions that an " \
          "anonymous caller cannot exercise on a public project: #{drift.to_a.sort.join(', ')}. " \
          "Either remove them from the YAML or update ProjectPolicy so anonymous can exercise them."
    end

    it 'lists only group permissions an anonymous caller can exercise on a public group' do
      drift = role.permissions(:group).reject do |permission|
        ::Users::Anonymous.can?(permission, public_group)
      end

      expect(drift).to be_empty,
        "config/authz/roles/public_anonymous.yml lists group permissions that an " \
          "anonymous caller cannot exercise on a public group: #{drift.to_a.sort.join(', ')}. " \
          "Either remove them from the YAML or update GroupPolicy so anonymous can exercise them."
    end
  end
end
