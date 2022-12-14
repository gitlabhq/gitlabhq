# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe PopulateReleasesAccessLevelFromRepository, :migration, feature_category: :navigation do
  let(:projects) { table(:projects) }
  let(:groups) { table(:namespaces) }
  let(:project_features) { table(:project_features) }

  let(:group) { groups.create!(name: 'test-group', path: 'test-group') }
  let(:project) { projects.create!(namespace_id: group.id, project_namespace_id: group.id) }
  let(:project_feature) do
    project_features.create!(project_id: project.id, pages_access_level: 20, **project_feature_attributes)
  end

  # repository_access_level and releases_access_level default to ENABLED
  describe '#up' do
    context 'when releases_access_level is greater than repository_access_level' do
      let(:project_feature_attributes) { { repository_access_level: ProjectFeature::PRIVATE } }

      it 'reduces releases_access_level to match repository_access_level' do
        expect { migrate! }.to change { project_feature.reload.releases_access_level }
                           .from(ProjectFeature::ENABLED)
                           .to(ProjectFeature::PRIVATE)
      end
    end

    context 'when releases_access_level is less than repository_access_level' do
      let(:project_feature_attributes) { { releases_access_level: ProjectFeature::DISABLED } }

      it 'does not change releases_access_level' do
        expect { migrate! }.not_to change { project_feature.reload.releases_access_level }
                           .from(ProjectFeature::DISABLED)
      end
    end
  end
end
