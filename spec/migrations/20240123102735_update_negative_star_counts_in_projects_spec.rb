# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateNegativeStarCountsInProjects, feature_category: :groups_and_projects do
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:projects) { table(:projects) }
  let(:project) do
    projects.create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
  end

  before do
    project.update_column(:star_count, -1)
  end

  describe "#up" do
    it 'updates the star_count' do
      migrate!

      expect(project.reload.star_count).to be_zero
    end
  end

  describe "#down" do
    it 'does nothing' do
      migrate!

      expect(project.reload.star_count).to be_zero

      schema_migrate_down!

      expect(project.reload.star_count).to be_zero
    end
  end
end
