# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ReferencesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path'
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:issue_note) { create(:note, noteable: issue, project: project) }
  let_it_be(:merge_request_note) { create(:note, noteable: merge_request, project: project) }
  let_it_be(:system_note) { create(:note, project: project, system: true, noteable: issue) }

  let_it_be(:random_project) { create(:project) }
  let_it_be(:random_issue) { create(:issue, project: random_project) }
  let_it_be(:random_merge_request) { create(:merge_request, source_project: random_project) }
  let_it_be(:random_issue_note) { create(:note, noteable: random_issue, project: random_project) }
  let_it_be(:random_mr_note) { create(:note, noteable: random_merge_request, project: random_project) }
  let_it_be(:random_system_note) { create(:note, system: true, noteable: random_issue, project: random_project) }

  let(:delay) { described_class::DELAY }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow(subject).to receive(:set_source_objects_counter)
  end

  describe '#run' do
    it "enqueues TransformReferencesWorker for the project's issues, mrs and their notes" do
      expect(BulkImports::TransformReferencesWorker).to receive(:perform_in)
        .with(delay, [issue.id], 'Issue', tracker.id)

      expect(BulkImports::TransformReferencesWorker).to receive(:perform_in)
        .with(delay * 2, array_including([issue_note.id, system_note.id]), 'Note', tracker.id)

      expect(BulkImports::TransformReferencesWorker).to receive(:perform_in)
        .with(delay * 3, [merge_request.id], 'MergeRequest', tracker.id)

      expect(BulkImports::TransformReferencesWorker).to receive(:perform_in)
        .with(delay * 4, [merge_request_note.id], 'Note', tracker.id)

      subject.run
    end

    it 'does not enqueue objects that do not belong to the project' do
      expect(BulkImports::TransformReferencesWorker).not_to receive(:perform_in)
        .with(anything, [random_issue.id], 'Issue', tracker.id)

      expect(BulkImports::TransformReferencesWorker).not_to receive(:perform_in)
        .with(anything, array_including([random_issue_note.id, random_system_note.id]), 'Note', tracker.id)

      expect(BulkImports::TransformReferencesWorker).not_to receive(:perform_in)
        .with(anything, [random_merge_request.id], 'MergeRequest', tracker.id)

      expect(BulkImports::TransformReferencesWorker).not_to receive(:perform_in)
        .with(anything, [random_mr_note.id], 'Note', tracker.id)

      subject.run
    end
  end
end
