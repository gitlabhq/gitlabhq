# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixProjectsWithoutProjectFeature, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  # This migration inserts project_features via raw SQL, bypassing ActiveRecord, so
  # it cannot rely on ProjectFeature#set_model_features_access_level. It must set the
  # model registry / experiments access levels itself; without a DB default they would
  # otherwise insert NULL. This is the path that caused INC-11487.
  let!(:private_project) { create_project('private-namespace', Gitlab::VisibilityLevel::PRIVATE) }
  let!(:internal_project) { create_project('internal-namespace', Gitlab::VisibilityLevel::INTERNAL) }
  let!(:public_project) { create_project('public-namespace', Gitlab::VisibilityLevel::PUBLIC) }

  subject(:perform) { described_class.new.perform(private_project.id, public_project.id) }

  it 'creates the missing project_features with visibility-based model access levels', :aggregate_failures do
    expect { perform }.to change { project_features.count }.by(3)

    expect(feature_for(private_project)).to have_attributes(
      model_registry_access_level: ProjectFeature::PRIVATE,
      model_experiments_access_level: ProjectFeature::PRIVATE
    )
    expect(feature_for(internal_project)).to have_attributes(
      model_registry_access_level: ProjectFeature::PRIVATE,
      model_experiments_access_level: ProjectFeature::PRIVATE
    )
    expect(feature_for(public_project)).to have_attributes(
      model_registry_access_level: ProjectFeature::ENABLED,
      model_experiments_access_level: ProjectFeature::ENABLED
    )
  end

  def create_project(namespace_path, visibility_level)
    namespace = namespaces.create!(name: namespace_path, path: namespace_path, organization_id: organization.id)

    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id,
      visibility_level: visibility_level
    )
  end

  def feature_for(project)
    project_features.find_by(project_id: project.id)
  end
end
