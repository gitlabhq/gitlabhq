# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::NullifyPersonalNamespaceIdOnGroupWikiEvents,
  feature_category: :wiki do
  let(:events) { table(:events) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }

  let!(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }

  let!(:group_namespace) do
    namespaces.create!(
      name: 'test-group',
      path: 'test-group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:personal_namespace) do
    namespaces.create!(
      name: 'test-user',
      path: 'test-user',
      type: 'User',
      organization_id: organization.id
    )
  end

  let!(:project_namespace) do
    namespaces.create!(
      name: 'test-project-ns',
      path: 'test-project-ns',
      type: 'Project',
      organization_id: organization.id
    )
  end

  let!(:user) do
    users.create!(
      email: 'test@example.com',
      username: 'test-user',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:project) do
    projects.create!(
      name: 'test-project',
      path: 'test-project',
      namespace_id: group_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  # The broken event: group wiki event with both group_id and personal_namespace_id set
  # (created during the bug window and then backfilled with group_id without clearing personal_namespace_id)
  let!(:broken_group_wiki_event) do
    events.create!(
      author_id: user.id,
      action: 6, # wiki_page action
      target_type: 'WikiPage::Meta',
      target_id: 1,
      group_id: group_namespace.id,
      personal_namespace_id: personal_namespace.id,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  # A correctly-formed group wiki event (only group_id set)
  let!(:correct_group_wiki_event) do
    events.create!(
      author_id: user.id,
      action: 6,
      target_type: 'WikiPage::Meta',
      target_id: 2,
      group_id: group_namespace.id,
      personal_namespace_id: nil,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  # A personal namespace wiki event (only personal_namespace_id set)
  let!(:personal_wiki_event) do
    events.create!(
      author_id: user.id,
      action: 6,
      target_type: 'WikiPage::Meta',
      target_id: 3,
      group_id: nil,
      personal_namespace_id: personal_namespace.id,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  # A project wiki event (only project_id set)
  let!(:project_wiki_event) do
    events.create!(
      author_id: user.id,
      action: 6,
      target_type: 'WikiPage::Meta',
      target_id: 4,
      project_id: project.id,
      personal_namespace_id: nil,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  # A non-wiki event with both group_id and personal_namespace_id (should not be touched)
  let!(:non_wiki_event_with_both) do
    events.create!(
      author_id: user.id,
      action: 1, # created action
      target_type: 'Issue',
      target_id: 5,
      group_id: group_namespace.id,
      personal_namespace_id: personal_namespace.id,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  describe '#perform' do
    subject(:perform_migration) { described_class.new(**migration_args).perform }

    it 'nullifies personal_namespace_id on broken group wiki events', :aggregate_failures do
      expect { perform_migration }
        .to change { broken_group_wiki_event.reload.personal_namespace_id }
        .from(personal_namespace.id).to(nil)
    end

    it 'does not modify correctly-formed group wiki events' do
      expect { perform_migration }
        .not_to change { correct_group_wiki_event.reload.personal_namespace_id }
    end

    it 'does not modify personal namespace wiki events' do
      expect { perform_migration }
        .not_to change { personal_wiki_event.reload.personal_namespace_id }
    end

    it 'does not modify project wiki events' do
      expect { perform_migration }
        .not_to change { project_wiki_event.reload.personal_namespace_id }
    end

    it 'does not modify non-wiki events with both group_id and personal_namespace_id' do
      expect { perform_migration }
        .not_to change { non_wiki_event_with_both.reload.personal_namespace_id }
    end

    it 'is idempotent' do
      2.times { perform_migration }

      expect(broken_group_wiki_event.reload.personal_namespace_id).to be_nil
      expect(broken_group_wiki_event.reload.group_id).to eq(group_namespace.id)
    end

    context 'when there are no broken events' do
      before do
        events.where(id: broken_group_wiki_event.id).update_all(personal_namespace_id: nil)
      end

      it 'does not raise an error' do
        expect { perform_migration }.not_to raise_error
      end
    end
  end

  private

  def migration_args
    min, max = events.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min || 0,
      end_id: max || 0,
      batch_table: 'events',
      batch_column: 'id',
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end
end
