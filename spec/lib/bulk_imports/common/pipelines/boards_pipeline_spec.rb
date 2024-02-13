# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::BoardsPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  let(:board_data) do
    {
      "name" => "Test Board",
      "lists" => [
        {
          "list_type" => "backlog",
          "position" => 0
        },
        {
          "list_type" => "closed",
          "position" => 1
        },
        {
          "list_type" => "label",
          "position" => 2,
          "label" => {
            "title" => "test",
            "type" => "GroupLabel",
            "group_id" => group.id
          }
        }
      ]
    }
  end

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(context) }

  before do
    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: board_data))
    end
    allow(subject).to receive(:set_source_objects_counter)
    group.add_owner(user)
  end

  context 'when issue board belongs to a project' do
    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        source_type: :project_entity,
        project: project,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'My-Destination-Group',
        destination_namespace: group.full_path
      )
    end

    describe '#run' do
      it 'imports issue boards into destination project' do
        expect { subject.run }.to change(::Board, :count).by(1)
        board = project.boards.find_by(name: board_data["name"])
        expect(board).to be_present
        expect(board.project.id).to eq(project.id)
        expect(board.lists.count).to eq(3)
        expect(board.lists.map(&:list_type).sort).to match_array(%w[backlog closed label])
        expect(board.lists.find_by(list_type: "label").label.title).to eq("test")
      end
    end
  end

  context 'when issue board belongs to a group' do
    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        group: group,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'My-Destination-Group',
        destination_namespace: group.full_path
      )
    end

    describe '#run' do
      it 'imports issue boards into destination group' do
        expect { subject.run }.to change(::Board, :count).by(1)
        board = group.boards.find_by(name: board_data["name"])
        expect(board).to be_present
        expect(board.group.id).to eq(group.id)
        expect(board.lists.count).to eq(3)
        expect(board.lists.map(&:list_type).sort).to match_array(%w[backlog closed label])
        expect(board.lists.find_by(list_type: "label").label.title).to eq("test")
      end
    end
  end
end
