# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddProjectFallbackToWikiUserMentionTrigger, feature_category: :team_planning do
  let(:notes) { table(:notes) }
  let(:wiki_page_meta) { table(:wiki_page_meta) }
  let(:mentions) { table(:wiki_page_meta_user_mentions) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'org', path: 'org') }
  let(:group) do
    namespaces.create!(name: 'grp', path: 'grp', type: 'Group', organization_id: organization.id)
  end

  let(:project_namespace) do
    namespaces.create!(
      name: 'prj', path: 'prj', type: 'Project', parent_id: group.id, organization_id: organization.id
    )
  end

  let(:project) do
    projects.create!(
      namespace_id: group.id, project_namespace_id: project_namespace.id, organization_id: organization.id
    )
  end

  let(:wiki_meta) { wiki_page_meta.create!(project_id: project.id, title: 'Home') }

  def insert_mention_for(note)
    mentions.create!(wiki_page_meta_id: wiki_meta.id, note_id: note.id, mentioned_users_ids: [1])
    mentions.where(note_id: note.id).first.namespace_id
  end

  describe 'the wiki user-mention sharding-key trigger' do
    context 'when the project_id fallback is present' do
      before do
        migrate!
      end

      it 'derives namespace_id from project_id when the project-keyed note has no namespace_id' do
        note = notes.create!(
          project_id: project.id, namespace_id: nil, noteable_type: 'WikiPage::Meta', note: 'x'
        )

        expect(insert_mention_for(note)).to eq(project_namespace.id)
      end

      it 'still copies namespace_id directly when the note carries it (group wiki)' do
        note = notes.create!(
          project_id: nil, namespace_id: group.id, noteable_type: 'WikiPage::Meta', note: 'x'
        )

        expect(insert_mention_for(note)).to eq(group.id)
      end
    end
  end
end
