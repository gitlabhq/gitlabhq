# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::MergeRequestsClearOldMergedCachedHtml, :background_operation, feature_category: :code_review_workflow do
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_metrics) { table(:merge_request_metrics) }

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

  let(:old_merge) { described_class::MERGED_CUTOFF.ago - 1.day }
  let(:recent_merge) { described_class::MERGED_CUTOFF.ago + 1.day }

  def operation
    described_class.new(
      min_cursor: [merge_requests.minimum(:id)],
      max_cursor: [merge_requests.maximum(:id)],
      batch_table: :merge_requests,
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

  it 'clears the cache on every merge request merged before the cutoff', :aggregate_failures do
    # Three eligible rows so more than one sub-batch (size 2) has to clear something.
    cleared = Array.new(3) { create_merge_request(merged_at: old_merge) }

    operation.perform

    cleared.each do |mr|
      reloaded = merge_requests.find(mr.id)
      expect(reloaded.title_html).to be_nil
      expect(reloaded.description_html).to be_nil
      expect(reloaded.cached_markdown_version).to be_nil
    end
  end

  it 'clears a merge request already above the target version' do
    mr = create_merge_request(merged_at: old_merge, cached_markdown_version: target_version + 1)

    operation.perform

    expect(merge_requests.find(mr.id).cached_markdown_version).to be_nil
  end

  it 'leaves merge requests that are not eligible untouched', :aggregate_failures do
    recently_merged = create_merge_request(merged_at: recent_merge)
    never_merged = create_merge_request(merged_at: nil)
    without_metrics = create_merge_request(merged_at: :skip)
    # Below the target version, so `MergeRequestsClearStaleCachedHtml` owns it.
    stale_version = create_merge_request(merged_at: old_merge, cached_markdown_version: target_version - 1)
    # No version at all, so its HTML is out of scope here too.
    no_version = create_merge_request(merged_at: old_merge, cached_markdown_version: nil)

    operation.perform

    [recently_merged, never_merged, without_metrics, stale_version, no_version].each do |mr|
      reloaded = merge_requests.find(mr.id)
      expect(reloaded.title_html).to eq(mr.title_html)
      expect(reloaded.description_html).to eq(mr.description_html)
      expect(reloaded.cached_markdown_version).to eq(mr.cached_markdown_version)
    end
  end

  it 'clears only the rows inside the sub-batch it was handed' do
    # Every other row is below the target version, so only half of each window clears.
    2.times do
      create_merge_request(merged_at: old_merge)
      create_merge_request(merged_at: old_merge, cached_markdown_version: target_version - 1)
    end

    operation_run = operation
    operation_run.perform

    expect(operation_run.batch_metrics.affected_rows[:update_all]).to eq([1, 1])
  end

  it 'iterates the whole table, filtering inside each sub-batch' do
    create_merge_request(merged_at: old_merge)
    5.times { create_merge_request(merged_at: recent_merge) }

    operation_run = operation
    operation_run.perform

    # Batching is unscoped, so all six rows are visited: three sub-batches run and the
    # two made up of recent merges clear nothing.
    expect(operation_run.batch_metrics.affected_rows[:update_all]).to eq([1, 0, 0])
  end

  it 'converges after a first pass, leaving nothing to rewrite', :aggregate_failures do
    create_merge_request(merged_at: old_merge)
    create_merge_request(merged_at: recent_merge)

    first_pass = operation
    first_pass.perform

    second_pass = operation
    second_pass.perform

    expect(first_pass.batch_metrics.affected_rows[:update_all].sum).to eq(1)
    expect(second_pass.batch_metrics.affected_rows[:update_all].sum).to eq(0)
  end

  private

  # `merged_at: :skip` creates a merge request with no `merge_request_metrics` row.
  def create_merge_request(merged_at:, cached_markdown_version: target_version)
    merge_request = merge_requests.create!(
      target_project_id: project.id,
      source_branch: 'feature',
      target_branch: 'master',
      title: 'MR',
      description: 'body',
      title_html: '<p>title</p>',
      description_html: '<p>body</p>',
      cached_markdown_version: cached_markdown_version
    )

    unless merged_at == :skip
      merge_request_metrics.create!(
        merge_request_id: merge_request.id,
        target_project_id: project.id,
        merged_at: merged_at
      )
    end

    merge_request
  end
end
