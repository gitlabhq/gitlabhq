# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveIncorrectlyOnboardedNamespacesFromOnboardingProgress, feature_category: :onboarding do
  let(:onboarding_progresses) { table(:onboarding_progresses) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  # namespace to keep with name Learn Gitlab
  let(:namespace1) { namespaces.create!(name: 'namespace1', type: 'Group', path: 'namespace1') }
  let!(:onboard_keep_1) { onboarding_progresses.create!(namespace_id: namespace1.id) }
  let!(:proj1) do
    proj_namespace = namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id)
    projects.create!(name: 'project', namespace_id: namespace1.id, project_namespace_id: proj_namespace.id)
  end

  let!(:learn_gitlab) do
    proj_namespace = namespaces.create!(name: 'projlg1', path: 'projlg1', type: 'Project', parent_id: namespace1.id)
    projects.create!(name: 'Learn GitLab', namespace_id: namespace1.id, project_namespace_id: proj_namespace.id)
  end

  # namespace to keep with name Learn GitLab - Ultimate trial
  let(:namespace2) { namespaces.create!(name: 'namespace2', type: 'Group', path: 'namespace2') }
  let!(:onboard_keep_2) { onboarding_progresses.create!(namespace_id: namespace2.id) }
  let!(:proj2) do
    proj_namespace = namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace2.id)
    projects.create!(name: 'project', namespace_id: namespace2.id, project_namespace_id: proj_namespace.id)
  end

  let!(:learn_gitlab2) do
    proj_namespace = namespaces.create!(name: 'projlg2', path: 'projlg2', type: 'Project', parent_id: namespace2.id)
    projects.create!(
      name: 'Learn GitLab - Ultimate trial',
      namespace_id: namespace2.id,
      project_namespace_id: proj_namespace.id
    )
  end

  # namespace to remove without learn gitlab project
  let(:namespace3) { namespaces.create!(name: 'namespace3', type: 'Group', path: 'namespace3') }
  let!(:onboarding_to_delete) { onboarding_progresses.create!(namespace_id: namespace3.id) }
  let!(:proj3) do
    proj_namespace = namespaces.create!(name: 'proj3', path: 'proj3', type: 'Project', parent_id: namespace3.id)
    projects.create!(name: 'project', namespace_id: namespace3.id, project_namespace_id: proj_namespace.id)
  end

  # namespace to remove without any projects
  let(:namespace4) { namespaces.create!(name: 'namespace4', type: 'Group', path: 'namespace4') }
  let!(:onboarding_to_delete_without_project) { onboarding_progresses.create!(namespace_id: namespace4.id) }

  describe '#up' do
    it 'deletes the onboarding for namespaces without learn gitlab' do
      expect { migrate! }.to change { onboarding_progresses.count }.by(-2)
      expect(onboarding_progresses.all).to contain_exactly(onboard_keep_1, onboard_keep_2)
    end
  end
end
