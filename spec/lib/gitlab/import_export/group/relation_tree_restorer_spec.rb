# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::RelationTreeRestorer, feature_category: :importers do
  describe '#restore', :clean_gitlab_redis_shared_state do
    let(:group) { create(:group, owners: user) }
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

    subject(:restore_relations) { relation_tree_restorer.restore }

    it 'restores group tree' do
      expect(restore_relations).to eq(true)
    end

    it 'logs top-level relation creation' do
      expect(shared.logger)
        .to receive(:info)
        .with(hash_including(message: '[Project/Group Import] Created new object relation'))
        .at_least(:once)

      restore_relations
    end

    describe 'relation object saving' do
      before do
        allow(shared.logger).to receive(:info).and_call_original
        allow(relation_reader).to receive(:consume_relation).and_call_original
      end

      context 'when relation object is new' do
        before do
          allow(relation_reader)
            .to receive(:consume_relation)
            .with(importable_name, 'boards')
            .and_return([[board, 0]])
        end

        context 'when relation object has invalid subrelations' do
          let(:board) do
            {
              'name' => 'test',
              'lists' => [List.new, List.new],
              'group_id' => importable.id
            }
          end

          it 'logs invalid subrelations' do
            expect(shared.logger)
              .to receive(:info)
              .with(
                message: '[Project/Group Import] Invalid subrelation',
                group_id: importable.id,
                relation_key: 'boards',
                error_messages: "Label can't be blank, Position can't be blank, and Position is not a number"
              )

            restore_relations

            board = importable.boards.last
            failure = importable.import_failures.first

            expect(importable.import_failures.count).to eq(2)
            expect(board.name).to eq('test')
            expect(failure.exception_class).to eq('ActiveRecord::RecordInvalid')
            expect(failure.source).to eq('RelationTreeRestorer#save_relation_object')
            expect(failure.exception_message)
              .to eq("Label can't be blank, Position can't be blank, and Position is not a number")
          end
        end
      end

      context 'when invalid relation object has a loggable external identifier' do
        before do
          allow(relation_reader)
            .to receive(:consume_relation)
            .with(importable_name, 'milestones')
            .and_return([
              [invalid_milestone, 0],
              [invalid_milestone_with_no_iid, 1]
            ])
        end

        let(:invalid_milestone) { build(:milestone, iid: 123, name: nil) }
        let(:invalid_milestone_with_no_iid) { build(:milestone, iid: nil, name: nil) }

        it 'logs invalid record with external identifier' do
          restore_relations

          iids_for_failures = importable.import_failures.collect { |f| [f.relation_key, f.external_identifiers] }
          expected_iids = [
            ["milestones", { "iid" => invalid_milestone.iid }],
            ["milestones", {}]
          ]

          expect(iids_for_failures).to match_array(expected_iids)
        end
      end

      context 'when relation object is persisted' do
        before do
          allow(relation_reader)
            .to receive(:consume_relation)
            .with(importable_name, 'labels')
            .and_return([[label, 0]])
        end

        context 'when relation object is invalid' do
          let(:label) { create(:group_label, group: group, title: 'test') }

          it 'saves import failure with nested errors' do
            label.priorities << [LabelPriority.new, LabelPriority.new]

            restore_relations

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
end
