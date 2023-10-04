# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db/post_migrate/20231003142706_lower_project_build_timeout_to_respect_max_validation.rb')

RSpec.describe LowerProjectBuildTimeoutToRespectMaxValidation, feature_category: :continuous_integration do
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:projects) { table(:projects) }
  let(:project) do
    projects.create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
  end

  before do
    project.update_column(:build_timeout, 2.months.to_i)
  end

  describe "#up" do
    it 'updates the build timeout' do
      expect(project.build_timeout).to be > 1.month.to_i

      migrate!

      expect(project.reload.build_timeout).to be <= 1.month.to_i
    end
  end

  describe "#down" do
    it 'does nothing' do
      expect(project.build_timeout).to be > 1.month.to_i

      migrate!

      expect(project.reload.build_timeout).to be <= 1.month.to_i

      schema_migrate_down!

      expect(project.reload.build_timeout).to be <= 1.month.to_i
    end
  end
end
