# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNamespaceIdOnDuoWorkflowSessionArtifacts, migration: :gitlab_main_org, feature_category: :compliance_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:workflows) { table(:duo_workflows_workflows) }
  let(:artifacts) { table(:duo_workflow_session_artifacts) }

  let(:organization) { organizations.create!(name: 'Org', path: 'org') }

  let(:group_namespace) do
    namespaces.create!(name: 'Group', path: 'group', organization_id: organization.id)
  end

  let(:project_namespace) do
    namespaces.create!(name: 'Project NS', path: 'project-ns', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(
      namespace_id: group_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:user) do
    users.create!(email: 'u@example.com', projects_limit: 10, username: 'u', organization_id: organization.id)
  end

  let(:project_workflow) { workflows.create!(project_id: project.id, user_id: user.id, goal: 'project goal') }
  let(:group_workflow) { workflows.create!(namespace_id: group_namespace.id, user_id: user.id, goal: 'group goal') }

  let!(:project_artifact) do
    artifacts.create!(
      workflow_id: project_workflow.id, user_id: user.id, project_id: project.id, namespace_id: nil,
      status: 0, workflow_definition: 'software_development',
      workflow_created_at: Time.current, workflow_updated_at: Time.current
    )
  end

  let!(:group_artifact) do
    artifacts.create!(
      workflow_id: group_workflow.id, user_id: user.id, project_id: nil, namespace_id: group_namespace.id,
      status: 0, workflow_definition: 'software_development',
      workflow_created_at: Time.current, workflow_updated_at: Time.current
    )
  end

  it 'backfills namespace_id from the project namespace and is reversible', :aggregate_failures do
    reversible_migration do |migration|
      migration.before -> {
        expect(project_artifact.reload.namespace_id).to be_nil
        expect(group_artifact.reload.namespace_id).to eq(group_namespace.id)
      }

      migration.after -> {
        expect(project_artifact.reload.namespace_id).to eq(project_namespace.id)
        expect(group_artifact.reload.namespace_id).to eq(group_namespace.id)
      }
    end
  end
end
