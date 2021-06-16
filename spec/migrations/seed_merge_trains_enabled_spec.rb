# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SeedMergeTrainsEnabled do
  describe 'migrate' do
    let(:project_ci_cd_settings) { table(:project_ci_cd_settings) }
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }

    context 'when on Gitlab.com' do
      before do
        namespace = namespaces.create!(name: 'hello', path: 'hello/')
        project1 = projects.create!(namespace_id: namespace.id)
        project2 = projects.create!(namespace_id: namespace.id)
        project_ci_cd_settings.create!(project_id: project1.id, merge_pipelines_enabled: true)
        project_ci_cd_settings.create!(project_id: project2.id, merge_pipelines_enabled: false)
      end

      it 'updates merge_trains_enabled to true for where merge_pipelines_enabled is true' do
        migrate!

        expect(project_ci_cd_settings.where(merge_trains_enabled: true).count).to be(1)
      end
    end
  end
end
