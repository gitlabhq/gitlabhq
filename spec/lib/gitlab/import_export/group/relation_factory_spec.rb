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
    let(:relation_sym) { :milestone }
    let(:relation_hash) { { 'description' => "I said to @sam the code should follow @bob's advice. @alice?" } }

    it 'updates username mentions with backticks' do
      expect(created_object.description).to eq("I said to `@sam` the code should follow `@bob`'s advice. `@alice`?")
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
