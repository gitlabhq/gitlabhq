# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::NotesClearStaleCachedHtml, :background_operation, feature_category: :code_review_workflow do
  let(:notes) { table(:notes) }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    table(:namespaces).create!(name: 'test', path: 'test', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  # Arbitrary; the operation only compares against it. How the bound itself
  # resolves across rollout states is covered in `Gitlab::MarkdownCache` specs.
  let(:target_version) { 200 }

  def operation
    described_class.new(
      min_cursor: [notes.minimum(:id)],
      max_cursor: [notes.maximum(:id)],
      batch_table: :notes,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  before do
    allow(::Gitlab::MarkdownCache)
      .to receive(:cached_markdown_version_for_bulk_clear).and_return(target_version)
  end

  it 'clears only notes strictly below the target version', :aggregate_failures do
    # Three stale rows so that more than one sub-batch (size 2) has to clear something.
    stale = Array.new(3) { create_note(cached_markdown_version: target_version - 1) }
    note_at = create_note(cached_markdown_version: target_version)
    note_above = create_note(cached_markdown_version: target_version + 1)
    # A NULL version with HTML still present is deliberately out of scope here, matching
    # the merge_requests operation.
    note_null = create_note(cached_markdown_version: nil)

    operation.perform

    stale.each do |note|
      cleared = notes.find(note.id)
      expect(cleared.note_html).to be_nil
      expect(cleared.cached_markdown_version).to be_nil
    end

    [note_at, note_above, note_null].each do |note|
      reloaded = notes.find(note.id)
      expect(reloaded.note_html).to eq(note.note_html)
      expect(reloaded.cached_markdown_version).to eq(note.cached_markdown_version)
    end
  end

  it 'clears notes regardless of what they hang off', :aggregate_failures do
    mr_note = create_note(cached_markdown_version: target_version - 1, noteable_type: 'MergeRequest')
    issue_note = create_note(cached_markdown_version: target_version - 1, noteable_type: 'Issue')
    commit_note = create_note(cached_markdown_version: target_version - 1, noteable_type: 'Commit')

    operation.perform

    [mr_note, issue_note, commit_note].each do |note|
      cleared = notes.find(note.id)
      expect(cleared.note_html).to be_nil
      expect(cleared.cached_markdown_version).to be_nil
    end
  end

  it 'clears only the rows inside the sub-batch it was handed' do
    2.times do
      create_note(cached_markdown_version: target_version - 1)
      create_note(cached_markdown_version: target_version)
    end

    operation_run = operation
    operation_run.perform

    # One stale row per sub-batch of two. A sub-batch reaching past its own window
    # would clear both stale rows at once and show up as [2, 0].
    expect(operation_run.batch_metrics.affected_rows[:update_all]).to match_array([1, 1])
  end

  it 'does not rewrite a row that is already cleared' do
    create_note(cached_markdown_version: nil, note_html: nil)

    operation_run = operation
    operation_run.perform

    expect(operation_run.batch_metrics.affected_rows[:update_all]).to eq([0])
  end

  it 'converges after a first pass, leaving nothing to rewrite', :aggregate_failures do
    create_note(cached_markdown_version: target_version - 1)
    create_note(cached_markdown_version: target_version)

    first_pass = operation
    first_pass.perform

    second_pass = operation
    second_pass.perform

    expect(first_pass.batch_metrics.affected_rows[:update_all].sum).to eq(1)
    expect(second_pass.batch_metrics.affected_rows[:update_all].sum).to eq(0)
  end

  private

  def create_note(cached_markdown_version:, note_html: '<p>note</p>', noteable_type: 'MergeRequest')
    notes.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      noteable_type: noteable_type,
      noteable_id: 1,
      note: 'note',
      note_html: note_html,
      cached_markdown_version: cached_markdown_version
    )
  end
end
