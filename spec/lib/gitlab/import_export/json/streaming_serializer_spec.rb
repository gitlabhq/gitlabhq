# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Json::StreamingSerializer do
  let_it_be(:user) { create(:user) }
  let_it_be(:release) { create(:release) }
  let_it_be(:group) { create(:group) }

  let_it_be(:exportable) do
    create(:project,
      :public,
      :repository,
      :issues_disabled,
      :wiki_enabled,
      :builds_private,
      description: 'description',
      releases: [release],
      group: group,
      approvals_before_merge: 1)
  end

  let_it_be(:issue) do
    create(:issue,
      assignees: [user],
      project: exportable)
  end

  let(:exportable_path) { 'project' }
  let(:json_writer) { instance_double('Gitlab::ImportExport::Json::LegacyWriter') }
  let(:hash) { { name: exportable.name, description: exportable.description }.stringify_keys }
  let(:include) { [] }
  let(:custom_orderer) { nil }

  let(:relations_schema) do
    {
      only: [:name, :description],
      include: include,
      preload: { issues: nil },
      export_reorder: custom_orderer
    }
  end

  subject do
    described_class.new(exportable, relations_schema, json_writer, exportable_path: exportable_path)
  end

  describe '#execute' do
    before do
      allow(json_writer).to receive(:write_attributes).with(exportable_path, hash)
    end

    it 'calls json_writer.write_attributes with proper params' do
      subject.execute
    end

    context 'with many relations' do
      let(:include) do
        [{ issues: { include: [] } }]
      end

      before do
        create_list(:issue, 3, project: exportable, relative_position: 10000) # ascending ids, same position positive
        create_list(:issue, 3, project: exportable, relative_position: -5000) # ascending ids, same position negative
        create_list(:issue, 3, project: exportable, relative_position: 0) # ascending ids, duplicate positions
        create_list(:issue, 3, project: exportable, relative_position: nil) # no position
        create_list(:issue, 3, :with_desc_relative_position, project: exportable ) # ascending ids, descending position
      end

      it 'calls json_writer.write_relation_array with proper params' do
        expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(issue.to_json))

        subject.execute
      end

      context 'default relation ordering' do
        it 'orders exported issues by primary key(:id)' do
          expected_issues = exportable.issues.reorder(:id).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'custom relation ordering ascending' do
        let(:custom_orderer) do
          {
            issues: {
              column: :relative_position,
              direction: :asc,
              nulls_position: :nulls_last
            }
          }
        end

        it 'orders exported issues by custom column(relative_position)' do
          expected_issues = exportable.issues.reorder(:relative_position, :id).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'custom relation ordering descending' do
        let(:custom_orderer) do
          {
            issues: {
              column: :relative_position,
              direction: :desc,
              nulls_position: :nulls_first
            }
          }
        end

        it 'orders exported issues by custom column(relative_position)' do
          expected_issues = exportable.issues.order_relative_position_desc.order(id: :desc).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end
    end

    context 'with single relation' do
      let(:group_options) do
        { include: [], only: [:name, :path, :description] }
      end

      let(:include) do
        [{ group: group_options }]
      end

      it 'calls json_writer.write_relation with proper params' do
        expect(json_writer).to receive(:write_relation).with(exportable_path, :group, group.to_json(group_options))

        subject.execute
      end
    end

    context 'with array relation' do
      let(:project_member) { create(:project_member, user: user) }
      let(:include) do
        [{ project_members: { include: [] } }]
      end

      before do
        allow(exportable).to receive(:project_members).and_return([project_member])
      end

      it 'calls json_writer.write_relation_array with proper params' do
        expect(json_writer).to receive(:write_relation_array).with(exportable_path, :project_members, array_including(project_member.to_json))

        subject.execute
      end
    end
  end

  describe '.batch_size' do
    context 'when export_reduce_relation_batch_size feature flag is enabled' do
      before do
        stub_feature_flags(export_reduce_relation_batch_size: true)
      end

      it 'returns 20' do
        expect(described_class.batch_size(exportable)).to eq(described_class::SMALLER_BATCH_SIZE)
      end
    end

    context 'when export_reduce_relation_batch_size feature flag is disabled' do
      before do
        stub_feature_flags(export_reduce_relation_batch_size: false)
      end

      it 'returns default batch size' do
        expect(described_class.batch_size(exportable)).to eq(described_class::BATCH_SIZE)
      end
    end
  end
end
