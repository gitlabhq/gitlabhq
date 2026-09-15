# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::NotesClearOldCachedHtml, :background_operation, feature_category: :code_review_workflow do
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

  let(:old_update) { described_class::UPDATED_CUTOFF.ago - 1.day }
  let(:recent_update) { described_class::UPDATED_CUTOFF.ago + 1.day }

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

  it 'clears the cache on every note untouched before the cutoff', :aggregate_failures do
    # Three eligible rows so more than one sub-batch (size 2) has to clear something.
    cleared = Array.new(3) { create_note(updated_at: old_update) }

    operation.perform

    cleared.each do |note|
      reloaded = notes.find(note.id)
      expect(reloaded.note_html).to be_nil
      expect(reloaded.cached_markdown_version).to be_nil
    end
  end

  it 'clears a note already above the target version' do
    note = create_note(updated_at: old_update, cached_markdown_version: target_version + 1)

    operation.perform

    expect(notes.find(note.id).cached_markdown_version).to be_nil
  end

  it 'ages notes out on updated_at, not created_at', :aggregate_failures do
    edited_recently = create_note(created_at: old_update, updated_at: recent_update)

    operation.perform

    reloaded = notes.find(edited_recently.id)
    expect(reloaded.note_html).to eq(edited_recently.note_html)
    expect(reloaded.cached_markdown_version).to eq(edited_recently.cached_markdown_version)
  end

  it 'clears notes regardless of what they hang off', :aggregate_failures do
    aged = %w[MergeRequest Issue Commit].map do |noteable_type|
      create_note(updated_at: old_update, noteable_type: noteable_type)
    end

    operation.perform

    aged.each do |note|
      reloaded = notes.find(note.id)
      expect(reloaded.note_html).to be_nil
      expect(reloaded.cached_markdown_version).to be_nil
    end
  end

  it 'leaves notes that are not eligible untouched', :aggregate_failures do
    recently_updated = create_note(updated_at: recent_update)
    # Below the target version, so `NotesClearStaleCachedHtml` owns it.
    stale_version = create_note(updated_at: old_update, cached_markdown_version: target_version - 1)
    # No version at all, so its HTML is out of scope here too.
    no_version = create_note(updated_at: old_update, cached_markdown_version: nil)

    operation.perform

    [recently_updated, stale_version, no_version].each do |note|
      reloaded = notes.find(note.id)
      expect(reloaded.note_html).to eq(note.note_html)
      expect(reloaded.cached_markdown_version).to eq(note.cached_markdown_version)
    end
  end

  it 'clears only the rows inside the sub-batch it was handed' do
    # Every other row is below the target version, so only half of each window clears.
    2.times do
      create_note(updated_at: old_update)
      create_note(updated_at: old_update, cached_markdown_version: target_version - 1)
    end

    operation_run = operation
    operation_run.perform

    expect(operation_run.batch_metrics.affected_rows[:update_all]).to eq([1, 1])
  end

  it 'iterates the whole table, filtering inside each sub-batch' do
    create_note(updated_at: old_update)
    5.times { create_note(updated_at: recent_update) }

    operation_run = operation
    operation_run.perform

    # Batching is unscoped, so all six rows are visited: three sub-batches run and the
    # two made up of recently updated notes clear nothing.
    expect(operation_run.batch_metrics.affected_rows[:update_all]).to eq([1, 0, 0])
  end

  it 'converges after a first pass, leaving nothing to rewrite', :aggregate_failures do
    create_note(updated_at: old_update)
    create_note(updated_at: recent_update)

    first_pass = operation
    first_pass.perform

    second_pass = operation
    second_pass.perform

    expect(first_pass.batch_metrics.affected_rows[:update_all].sum).to eq(1)
    expect(second_pass.batch_metrics.affected_rows[:update_all].sum).to eq(0)
  end

  private

  def create_note(
    updated_at:, created_at: nil, cached_markdown_version: target_version, noteable_type: 'MergeRequest')
    notes.create!(
      project_id: project.id,
      namespace_id: namespace.id,
      noteable_type: noteable_type,
      noteable_id: 1,
      note: 'note',
      note_html: '<p>note</p>',
      cached_markdown_version: cached_markdown_version,
      created_at: created_at || updated_at,
      updated_at: updated_at
    )
  end
end
