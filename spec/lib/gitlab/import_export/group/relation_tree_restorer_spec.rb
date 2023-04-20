# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::RelationTreeRestorer, feature_category: :importers do
  let(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let(:importable) { create(:group, parent: group) }

  include_context 'relation tree restorer shared context' do
    let(:importable_name) { 'groups/4353' }
  end

  let(:path) { Rails.root.join('spec/fixtures/lib/gitlab/import_export/group_exports/no_children/tree') }
  let(:relation_reader) do
    Gitlab::ImportExport::Json::NdjsonReader.new(path)
  end

  let(:reader) do
    Gitlab::ImportExport::Reader.new(
      shared: shared,
      config: Gitlab::ImportExport::Config.new(config: Gitlab::ImportExport.group_config_file).to_h
    )
  end

  let(:members_mapper) do
    Gitlab::ImportExport::MembersMapper.new(
      exported_members: relation_reader.consume_relation(importable_name, 'members').map(&:first),
      user: user,
      importable: importable
    )
  end

  let(:relation_tree_restorer) do
    described_class.new(
      user: user,
      shared: shared,
      relation_reader: relation_reader,
      object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
      members_mapper: members_mapper,
      relation_factory: Gitlab::ImportExport::Group::RelationFactory,
      reader: reader,
      importable: importable,
      importable_path: importable_name,
      importable_attributes: attributes
    )
  end

  subject { relation_tree_restorer.restore }

  it 'restores group tree' do
    expect(subject).to eq(true)
  end

  it 'logs top-level relation creation' do
    expect(shared.logger)
      .to receive(:info)
      .with(hash_including(message: '[Project/Group Import] Created new object relation'))
      .at_least(:once)

    subject
  end

  describe 'relation object saving' do
    before do
      allow(shared.logger).to receive(:info).and_call_original
      allow(relation_reader).to receive(:consume_relation).and_call_original

      allow(relation_reader)
        .to receive(:consume_relation)
        .with(importable_name, 'labels')
        .and_return([[label, 0]])
    end

    context 'when relation object is new' do
      context 'when relation object has invalid subrelations' do
        let(:label) do
          {
            'title' => 'test',
            'priorities' => [LabelPriority.new, LabelPriority.new],
            'type' => 'GroupLabel'
          }
        end

        it 'logs invalid subrelations' do
          expect(shared.logger)
            .to receive(:info)
            .with(
              message: '[Project/Group Import] Invalid subrelation',
              group_id: importable.id,
              relation_key: 'labels',
              error_messages: "Project can't be blank, Priority can't be blank, and Priority is not a number"
            )

          subject

          label = importable.labels.first
          failure = importable.import_failures.first

          expect(importable.import_failures.count).to eq(2)
          expect(label.title).to eq('test')
          expect(failure.exception_class).to eq('ActiveRecord::RecordInvalid')
          expect(failure.source).to eq('RelationTreeRestorer#save_relation_object')
          expect(failure.exception_message)
            .to eq("Project can't be blank, Priority can't be blank, and Priority is not a number")
        end
      end
    end

    context 'when relation object is persisted' do
      context 'when relation object is invalid' do
        let(:label) { create(:group_label, group: group, title: 'test') }

        it 'saves import failure with nested errors' do
          label.priorities << [LabelPriority.new, LabelPriority.new]

          subject

          failure = importable.import_failures.first

          expect(importable.labels.count).to eq(0)
          expect(importable.import_failures.count).to eq(1)
          expect(failure.exception_class).to eq('ActiveRecord::RecordInvalid')
          expect(failure.source).to eq('process_relation_item!')
          expect(failure.exception_message)
            .to eq("Validation failed: Priorities is invalid, Project can't be blank, Priority can't be blank, " \
                   "Priority is not a number, Project can't be blank, Priority can't be blank, " \
                   "Priority is not a number")
        end
      end
    end
  end
end
