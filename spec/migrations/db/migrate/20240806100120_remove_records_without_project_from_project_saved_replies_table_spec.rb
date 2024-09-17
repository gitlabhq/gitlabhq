# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveRecordsWithoutProjectFromProjectSavedRepliesTable, feature_category: :code_review_workflow, migration: :gitlab_main, schema: 20240802194749 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_saved_replies) { table(:project_saved_replies) }

  let!(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:project_namespace) { namespaces.create!(name: 'project1', path: 'project1', type: 'Project') }
  let!(:project) do
    projects.create!(
      name: 'project1', path: 'project1', namespace_id: group1.id, project_namespace_id: project_namespace.id
    )
  end

  describe '#up' do
    it do
      project_saved_replies.create!(project_id: project.id, name: 'Test', content: 'Test')

      migrate!

      expect { migrate! }.to change { project_saved_replies.count }.by(0)
    end
  end
end
