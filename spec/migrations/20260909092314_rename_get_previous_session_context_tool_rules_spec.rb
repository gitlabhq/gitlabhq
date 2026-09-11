# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenameGetPreviousSessionContextToolRules, feature_category: :ai_agents do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ai_tool_rules) { table(:ai_tool_rules) }

  let!(:organization) { organizations.create!(name: 'Org', path: 'org') }
  let!(:namespace) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  def create_project(path)
    project_namespace = namespaces.create!(name: path, path: path, type: 'Project', organization_id: organization.id)

    projects.create!(name: path, path: path, namespace_id: namespace.id,
      project_namespace_id: project_namespace.id, organization_id: organization.id)
  end

  describe '#up' do
    context 'when there is no conflicting get_session_context row' do
      let!(:stale_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, tool_name: 'get_previous_session_context', web_access: 0)
      end

      it 'renames the row to get_session_context' do
        migrate!

        expect(stale_rule.reload.tool_name).to eq('get_session_context')
      end
    end

    context 'when a get_session_context row already exists for the same namespace/project' do
      let!(:stale_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, tool_name: 'get_previous_session_context',
          web_access: 2, local_access: 2, background_access: 2)
      end

      let!(:fresh_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, tool_name: 'get_session_context', web_access: 0)
      end

      it 'merges the stale row into the fresh row, keeping the fresh value and backfilling the rest',
        :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:warn).once.with(
          hash_including(message: a_string_including('Merged stale ai_tool_rules row'), ai_tool_rule_id: stale_rule.id)
        ).and_call_original

        migrate!

        expect(ai_tool_rules.where(id: stale_rule.id)).not_to exist
        expect(fresh_rule.reload).to have_attributes(
          tool_name: 'get_session_context', web_access: 0, local_access: 2, background_access: 2
        )
      end
    end

    context 'when a get_session_context row is created concurrently, after the conflict check' do
      let!(:stale_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, tool_name: 'get_previous_session_context',
          web_access: 2, local_access: 2, background_access: 2)
      end

      before do
        # The first find_by call would really return nil here (nothing conflicts yet). It's stubbed to
        # also create the get_session_context row as a side effect, simulating a concurrent admin edit
        # landing right after the check, so the real update_column below hits a genuine unique violation.
        call_count = 0
        allow(described_class::MigrationAiToolRule).to receive(:find_by).and_wrap_original do |original, **args|
          call_count += 1

          if call_count == 1
            ai_tool_rules.create!(namespace_id: namespace.id, tool_name: 'get_session_context', web_access: 1)
            nil
          else
            original.call(**args)
          end
        end
      end

      it 'merges the stale row into the concurrently created row instead of raising', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:warn).once.with(
          hash_including(message: a_string_including('Merged stale ai_tool_rules row'), ai_tool_rule_id: stale_rule.id)
        ).and_call_original

        expect { migrate! }.not_to raise_error

        expect(ai_tool_rules.where(id: stale_rule.id)).not_to exist
        fresh_rule = ai_tool_rules.find_by(namespace_id: namespace.id, tool_name: 'get_session_context')
        expect(fresh_rule).to have_attributes(web_access: 1, local_access: 2, background_access: 2)
      end
    end

    context 'when a get_session_context row exists in the same namespace but a different project' do
      let!(:project_a) { create_project('project-a') }
      let!(:project_b) { create_project('project-b') }

      let!(:stale_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, project_id: project_a.id,
          tool_name: 'get_previous_session_context', web_access: 0)
      end

      let!(:unrelated_new_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, project_id: project_b.id,
          tool_name: 'get_session_context', web_access: 1)
      end

      it 'renames the stale row, since the conflict check is scoped per project' do
        migrate!

        expect(stale_rule.reload.tool_name).to eq('get_session_context')
        expect(unrelated_new_rule.reload.tool_name).to eq('get_session_context')
      end
    end

    context 'when rows belong to different namespaces' do
      let!(:other_namespace) do
        namespaces.create!(name: 'other', path: 'other', type: 'Group', organization_id: organization.id)
      end

      let!(:stale_rule) do
        ai_tool_rules.create!(namespace_id: namespace.id, tool_name: 'get_previous_session_context', web_access: 0)
      end

      let!(:unrelated_new_rule) do
        ai_tool_rules.create!(namespace_id: other_namespace.id, tool_name: 'get_session_context', web_access: 1)
      end

      it 'renames the stale row, since the conflict check is scoped per namespace' do
        migrate!

        expect(stale_rule.reload.tool_name).to eq('get_session_context')
        expect(unrelated_new_rule.reload.tool_name).to eq('get_session_context')
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      stale_rule = ai_tool_rules.create!(
        namespace_id: namespace.id, tool_name: 'get_previous_session_context', web_access: 0
      )

      migrate!
      schema_migrate_down!

      expect(stale_rule.reload.tool_name).to eq('get_session_context')
    end
  end
end
