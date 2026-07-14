# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillMergeRequestFilterOnAiFlowTriggers,
  migration: :gitlab_main_org,
  feature_category: :code_suggestions,
  migration_version: 20260623154606 do
  let(:migration) { described_class.new }
  let(:flow_triggers) { table(:ai_flow_triggers) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let(:merge_request) { 6 }
  let(:mention) { 0 }
  let(:approved_filter) do
    { 'merge_request' => { 'rules' => [{ 'field' => 'action', 'operator' => 'in', 'value' => ['approved'] }] } }
  end

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let(:namespace) do
    namespaces.create!(name: 'test', path: 'test', type: 'Group', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(
      name: 'test',
      path: 'test',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:user) do
    users.create!(
      email: "test-bot@example.com",
      username: "test-bot-#{SecureRandom.hex(4)}",
      organization_id: organization.id,
      projects_limit: 0,
      user_type: 3
    )
  end

  describe '#up' do
    context 'when a merge_request trigger has an empty filter' do
      let!(:trigger) do
        flow_triggers.create!(
          project_id: project.id,
          user_id: user.id,
          config_path: '.gitlab/ai/test.yml',
          description: 'empty filter',
          event_types: [merge_request],
          filter: {}
        )
      end

      it 'backfills the approved action filter' do
        migration.up

        expect(trigger.reload.filter).to eq(approved_filter)
      end
    end

    context 'when a merge_request trigger already has a filter' do
      let(:existing_filter) do
        { 'merge_request' => { 'rules' => [{ 'field' => 'action', 'operator' => 'in',
                                             'value' => ['code_conflict'] }] } }
      end

      let!(:trigger) do
        flow_triggers.create!(
          project_id: project.id,
          user_id: user.id,
          config_path: '.gitlab/ai/test.yml',
          description: 'has filter',
          event_types: [merge_request],
          filter: existing_filter
        )
      end

      it 'does not overwrite the existing filter' do
        migration.up

        expect(trigger.reload.filter).to eq(existing_filter)
      end
    end

    context 'when a trigger has merge_request alongside other event types' do
      let!(:trigger) do
        flow_triggers.create!(
          project_id: project.id,
          user_id: user.id,
          config_path: '.gitlab/ai/test.yml',
          description: 'mixed events',
          event_types: [mention, merge_request],
          filter: {}
        )
      end

      it 'backfills the approved action filter' do
        migration.up

        expect(trigger.reload.filter).to eq(approved_filter)
      end
    end

    context 'when a trigger has no merge_request event type' do
      let!(:trigger) do
        flow_triggers.create!(
          project_id: project.id,
          user_id: user.id,
          config_path: '.gitlab/ai/test.yml',
          description: 'mention only',
          event_types: [mention],
          filter: {}
        )
      end

      it 'does not modify the filter' do
        migration.up

        expect(trigger.reload.filter).to eq({})
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { migration.down }.not_to raise_error
    end
  end
end
