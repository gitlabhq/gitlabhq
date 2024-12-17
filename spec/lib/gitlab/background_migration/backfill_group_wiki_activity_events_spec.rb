# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGroupWikiActivityEvents, feature_category: :wiki do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:events) { table(:events) }
  let(:wiki_page_meta) { table(:wiki_page_meta) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'Foobar', path: 'path1') }
  let(:user) { table(:users).create!(email: 'user1@example.com', projects_limit: 10) }
  let(:group) { namespaces.create!(type: 'Group', name: 'group1', path: 'path1', organization_id: organization.id) }
  let(:other_group) do
    namespaces.create!(type: 'Group', name: 'group2', path: 'path2', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(namespace_id: group.id, project_namespace_id: group.id, organization_id: organization.id)
  end

  let(:project_wiki_page_meta) { wiki_page_meta.create!(project_id: project.id, title: 'title1') }
  let(:group_wiki_page_meta) { wiki_page_meta.create!(namespace_id: group.id, title: 'title2') }
  let(:other_group_wiki_page_meta) { wiki_page_meta.create!(namespace_id: other_group.id, title: 'title3') }

  let!(:event_with_project_wiki) do
    events.create!(
      author_id: user.id,
      action: 'commented',
      project_id: nil,
      group_id: nil,
      personal_namespace_id: group.id,
      target_type: 'WikiPage::Meta',
      target_id: project_wiki_page_meta.id
    )
  end

  let!(:event_with_group_wiki) do
    events.create!(
      author_id: user.id,
      action: 'commented',
      project_id: nil,
      group_id: nil,
      personal_namespace_id: group.id,
      target_type: 'WikiPage::Meta',
      target_id: group_wiki_page_meta.id
    )
  end

  let!(:valid_event_with_project_wiki) do
    events.create!(
      author_id: user.id,
      action: 'commented',
      project_id: project_wiki_page_meta.project_id,
      group_id: nil,
      personal_namespace_id: group.id,
      target_type: 'WikiPage::Meta',
      target_id: project_wiki_page_meta.id
    )
  end

  let!(:valid_event_with_group_wiki) do
    events.create!(
      author_id: user.id,
      action: 'commented',
      project_id: nil,
      group_id: group_wiki_page_meta.namespace_id,
      personal_namespace_id: group.id,
      target_type: 'WikiPage::Meta',
      target_id: other_group_wiki_page_meta.id
    )
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: event_with_project_wiki.id,
        end_id: event_with_group_wiki.id,
        batch_table: :events,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    context 'for project wiki page events' do
      it 'backfills only wiki page events without group_id and project_id' do
        expect { migration.perform }.to change { event_with_group_wiki.reload.group_id }
          .from(nil)
          .to(group_wiki_page_meta.namespace_id)
          .and not_change { event_with_group_wiki.reload.project_id }
          .and not_change { event_with_project_wiki.reload.project_id }
          .and not_change { event_with_project_wiki.reload.group_id }
          .and not_change { valid_event_with_project_wiki.reload.project_id }
          .and not_change { valid_event_with_project_wiki.reload.project_id }
          .and not_change { valid_event_with_group_wiki.reload.group_id }
          .and not_change { valid_event_with_group_wiki.reload.group_id }
      end
    end
  end
end
