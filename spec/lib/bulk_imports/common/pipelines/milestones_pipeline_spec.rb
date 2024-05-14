# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::MilestonesPipeline, feature_category: :importers do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:bulk_import) { create(:bulk_import, user: user) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:source_project_id) { nil } # if set, then exported_milestone is a project milestone
  let(:source_group_id) { nil } # if set, then exported_milestone is a group milestone
  let(:exported_milestone_for_project) do
    exported_milestone_for_group.merge(
      'events' => [{
        'project_id' => source_project_id,
        'author_id' => 9,
        'created_at' => "2021-08-12T19:12:49.810Z",
        'updated_at' => "2021-08-12T19:12:49.810Z",
        'target_type' => "Milestone",
        'group_id' => source_group_id,
        'fingerprint' => 'f270eb9b27d0',
        'id' => 66,
        'action' => "created"
      }]
    )
  end

  let(:exported_milestone_for_group) do
    {
      'id' => 1,
      'title' => "v1.0",
      'project_id' => source_project_id,
      'description' => "Amet velit repellat ut rerum aut cum.",
      'due_date' => "2019-11-22",
      'created_at' => "2019-11-20T17:02:14.296Z",
      'updated_at' => "2019-11-20T17:02:14.296Z",
      'state' => "active",
      'iid' => 2,
      'start_date' => "2019-11-21",
      'group_id' => source_group_id
    }
  end

  before do
    group.add_owner(user)

    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: exported_milestones))
    end

    allow(subject).to receive(:set_source_objects_counter)
  end

  subject { described_class.new(context) }

  shared_examples 'bulk_imports milestones pipeline' do
    let(:tested_entity) { nil }

    describe '#run' do
      it 'imports milestones into destination' do
        expect { subject.run }.to change(Milestone, :count).by(1)

        imported_milestone = tested_entity.milestones.first

        expect(imported_milestone.title).to eq("v1.0")
        expect(imported_milestone.description).to eq("Amet velit repellat ut rerum aut cum.")
        expect(imported_milestone.due_date.to_s).to eq("2019-11-22")
        expect(imported_milestone.created_at).to eq("2019-11-20T17:02:14.296Z")
        expect(imported_milestone.updated_at).to eq("2019-11-20T17:02:14.296Z")
        expect(imported_milestone.start_date.to_s).to eq("2019-11-21")
      end
    end

    describe '#load' do
      context 'when milestone is not persisted' do
        it 'saves the milestone' do
          milestone = build(:milestone, group: group)

          expect(milestone).to receive(:save!)

          subject.load(context, milestone)
        end
      end

      context 'when milestone is missing' do
        it 'returns' do
          expect(subject.load(context, nil)).to be_nil
        end
      end
    end
  end

  context 'group milestone' do
    let(:exported_milestones) { [[exported_milestone_for_group, 0]] }
    let(:entity) do
      create(
        :bulk_import_entity,
        group: group,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'My-Destination-Group',
        destination_namespace: group.full_path
      )
    end

    it_behaves_like 'bulk_imports milestones pipeline' do
      let(:tested_entity) { group }
      let(:source_group_id) { 1 }
    end
  end

  context 'project milestone' do
    let(:project) { create(:project, group: group) }
    let(:exported_milestones) { [[exported_milestone_for_project, 0]] }

    let(:entity) do
      create(
        :bulk_import_entity,
        :project_entity,
        project: project,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'My-Destination-Project',
        destination_namespace: group.full_path
      )
    end

    it_behaves_like 'bulk_imports milestones pipeline' do
      let(:tested_entity) { project }
      let(:source_project_id) { 1 }

      it 'imports events' do
        subject.run

        imported_event = tested_entity.milestones.first.events.first

        expect(imported_event.created_at).to eq("2021-08-12T19:12:49.810Z")
        expect(imported_event.updated_at).to eq("2021-08-12T19:12:49.810Z")
        expect(imported_event.target_type).to eq("Milestone")
        expect(imported_event.fingerprint).to eq("f270eb9b27d0")
        expect(imported_event.action).to eq("created")
      end
    end
  end
end
