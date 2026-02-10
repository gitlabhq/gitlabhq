# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::RelationFactory, feature_category: :importers do
  let(:group) { create(:group) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:admin) { create(:admin) }
  let(:importer_user) { admin }
  let(:excluded_keys) { [] }
  let(:created_object) do
    described_class.create( # rubocop:disable Rails/SaveBang
      relation_sym: relation_sym,
      relation_hash: relation_hash,
      relation_index: 1,
      members_mapper: members_mapper,
      object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
      user: importer_user,
      importable: group,
      import_source: ::Import::SOURCE_GROUP_EXPORT_IMPORT,
      excluded_keys: excluded_keys,
      rewrite_mentions: true
    )
  end

  context 'label object' do
    let(:relation_sym) { :group_label }
    let(:id) { random_id }
    let(:original_group_id) { random_id }

    let(:relation_hash) do
      {
        'id' => 123456,
        'title' => 'Bruffefunc',
        'color' => '#1d2da4',
        'project_id' => nil,
        'created_at' => '2019-11-20T17:02:20.546Z',
        'updated_at' => '2019-11-20T17:02:20.546Z',
        'template' => false,
        'description' => 'Description',
        'group_id' => original_group_id,
        'type' => 'GroupLabel',
        'priorities' => [],
        'textColor' => '#FFFFFF'
      }
    end

    it 'does not have the original ID' do
      expect(created_object.id).not_to eq(id)
    end

    it 'does not have the original group_id' do
      expect(created_object.group_id).not_to eq(original_group_id)
    end

    it 'has the new group_id' do
      expect(created_object.group_id).to eq(group.id)
    end

    context 'excluded attributes' do
      let(:excluded_keys) { %w[description] }

      it 'are removed from the imported object' do
        expect(created_object.description).to be_nil
      end
    end
  end

  it_behaves_like 'Notes user references' do
    let(:importable) { group }
    let(:relation_hash) do
      {
        'id' => 4947,
        'note' => 'note',
        'noteable_type' => 'Epic',
        'author_id' => 999,
        'created_at' => '2016-11-18T09:29:42.634Z',
        'updated_at' => '2016-11-18T09:29:42.634Z',
        'project_id' => 1,
        'attachment' => {
          'url' => nil
        },
        'noteable_id' => 377,
        'system' => true,
        'author' => {
          'name' => 'Administrator'
        },
        'events' => []
      }
    end
  end

  context 'when relation is a milestone' do
    let_it_be(:relation_sym) { :milestone }
    let_it_be(:relation_hash) do
      {
        'title' => '20.0',
        'description' => "I said to @sam the code should follow @bob's advice. @alice?"
      }
    end

    it 'updates username mentions with backticks' do
      expect(created_object.description).to eq("I said to `@sam` the code should follow `@bob`'s advice. `@alice`?")
    end

    context 'when the imported milestone title is nil' do
      let_it_be(:relation_hash) do
        {
          'description' => "I said to @sam the code should follow @bob's advice. @alice?"
        }
      end

      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:other_milestone) { create(:milestone, group: parent_group) }

      it 'creates the milestone' do
        expect(created_object).to be_a(Milestone)
        expect(created_object.title).to be_nil
        expect(created_object.group_id).to eq(group.id)
      end
    end

    context 'when the milestone title is unique to the namespace hierarchy' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:other_milestone) { create(:milestone, group: parent_group, title: '18.0') }

      it 'creates the milestone' do
        expect(created_object).to be_a(Milestone)
        expect(created_object.title).to eq('20.0')
        expect(created_object.group_id).to eq(group.id)
      end
    end

    context 'when the sibling group has a matching milestone title' do
      let_it_be(:parent_group) { create(:group) }

      let_it_be(:group) { create(:group, parent: parent_group) }

      let_it_be(:group_2) { create(:group, parent: parent_group) }
      let_it_be(:group_2_milestone) { create(:milestone, group: group_2, title: '20.0') }

      it 'does not change the milestone title' do
        expect(created_object).to be_a(Milestone)
        expect(created_object.title).to eq('20.0')
        expect(created_object.group_id).to eq(group.id)
      end
    end

    context 'when the milestone title is not unique to the namespace hierarchy' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:sub_group) { create(:group, parent: group) }
      let_it_be(:project) { create(:project, group: sub_group) }
      let_it_be(:parent_milestone) { create(:milestone, group: parent_group, title: '18.0') }
      let_it_be(:sub_group_milestone) { create(:milestone, group: sub_group, title: '19.0') }
      let_it_be(:project_milestone) { create(:milestone, project: project, title: '20.0') }
      let_it_be(:new_milestone_title_pattern) { /20\.0.*imported/ }

      it 'updates the milestone title and logs the event' do
        m = '[Project/Group Import] Updating milestone title - source title used by existing group or project milestone'
        expect(::Import::Framework::Logger).to receive_message_chain(:build, :info).with(
          hash_including(
            message: m,
            importable_id: group.id,
            relation_key: :milestone,
            existing_milestone_title: '20.0',
            existing_group_id: nil,
            existing_project_id: project.id,
            new_milestone_title: match(new_milestone_title_pattern)
          )
        )

        expect(created_object).to be_a(Milestone)
        expect(created_object.title).to match(new_milestone_title_pattern)
        expect(created_object.group_id).to eq(group.id)
        expect(parent_milestone.group_id).to eq(parent_group.id)
      end
    end
  end

  context 'when relation is namespace_settings' do
    let(:relation_sym) { :namespace_settings }
    let(:relation_hash) do
      {
        'namespace_id' => 1,
        'prevent_forking_outside_group' => true,
        'prevent_sharing_groups_outside_hierarchy' => true
      }
    end

    it do
      expect(created_object).to eq(nil)
    end
  end

  context 'when relation is event' do
    let(:relation_sym) { :events }
    let(:relation_hash) do
      {
        'author_id' => 1,
        'action' => 'created',
        'target_type' => 'Issue'
      }
    end

    it 'builds an event' do
      expect(created_object).to be_an(Event)
    end

    context 'when author ID maps to nil user' do
      let(:members_mapper) { double('members_mapper', map: {}) }

      it 'does not build an Event' do
        expect(created_object).to be_nil
      end
    end
  end

  def random_id
    rand(1000..10000)
  end
end
