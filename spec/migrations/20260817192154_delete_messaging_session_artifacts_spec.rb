# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteMessagingSessionArtifacts, migration: :gitlab_main,
  feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:workflows) { table(:duo_workflows_workflows) }
  let(:artifacts) { table(:duo_workflow_session_artifacts) }

  let(:organization) { organizations.create!(name: 'org', path: 'org') }
  let(:namespace) do
    namespaces.create!(name: 'group', path: 'group', organization_id: organization.id)
  end

  let(:user) do
    users.create!(username: 'user', email: 'user@example.com', projects_limit: 0,
      organization_id: organization.id)
  end

  let!(:slack_workflow) do
    workflows.create!(user_id: user.id, namespace_id: namespace.id,
      messaging_callback_context: { 'adapter' => 'slack' })
  end

  let!(:note_mention_workflow) do
    workflows.create!(user_id: user.id, namespace_id: namespace.id,
      messaging_callback_context: { 'adapter' => 'gitlab_duo_note', 'note_id' => 1 })
  end

  let!(:regular_workflow) do
    workflows.create!(user_id: user.id, namespace_id: namespace.id)
  end

  let!(:slack_artifact) { create_artifact(slack_workflow) }
  let!(:note_mention_artifact) { create_artifact(note_mention_workflow) }
  let!(:regular_artifact) { create_artifact(regular_workflow) }

  it 'deletes only artifacts of invoker-private messaging workflows', :aggregate_failures do
    migrate!

    expect(artifacts.where(id: slack_artifact.id)).to be_empty
    expect(artifacts.where(id: note_mention_artifact.id)).to exist
    expect(artifacts.where(id: regular_artifact.id)).to exist
  end

  def create_artifact(workflow)
    artifacts.create!(
      workflow_id: workflow.id,
      user_id: user.id,
      namespace_id: namespace.id,
      workflow_created_at: workflow.created_at,
      workflow_updated_at: workflow.updated_at
    )
  end
end
