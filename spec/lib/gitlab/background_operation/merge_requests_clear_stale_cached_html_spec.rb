# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundOperation::MergeRequestsClearStaleCachedHtml, :background_operation, feature_category: :code_review_workflow do
  let(:merge_requests) { table(:merge_requests) }

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

  it 'clears only merge requests strictly below the target version', :aggregate_failures do
    # Three stale rows so that more than one sub-batch (size 2) has to clear something.
    stale = Array.new(3) { create_merge_request(cached_markdown_version: target_version - 1) }
    mr_at = create_merge_request(cached_markdown_version: target_version)
    mr_above = create_merge_request(cached_markdown_version: target_version + 1)
    # A NULL version with HTML still present is deliberately out of scope here, and is
    # handled in https://gitlab.com/gitlab-org/gitlab/-/issues/617370.
    mr_null = create_merge_request(cached_markdown_version: nil)

    operation.perform

    stale.each do |mr|
      cleared = merge_requests.find(mr.id)
      expect(cleared.title_html).to be_nil
      expect(cleared.description_html).to be_nil
      expect(cleared.cached_markdown_version).to be_nil
    end

    [mr_at, mr_above, mr_null].each do |mr|
      reloaded = merge_requests.find(mr.id)
      expect(reloaded.title_html).to eq(mr.title_html)
      expect(reloaded.description_html).to eq(mr.description_html)
      expect(reloaded.cached_markdown_version).to eq(mr.cached_markdown_version)
    end
  end

  it 'clears only the rows inside the sub-batch it was handed' do
    2.times do
      create_merge_request(cached_markdown_version: target_version - 1)
      create_merge_request(cached_markdown_version: target_version)
    end

    operation_run = operation
    operation_run.perform

    # One stale row per sub-batch of two. A sub-batch reaching past its own window
    # would clear both stale rows at once and show up as [2, 0].
    expect(operation_run.batch_metrics.affected_rows[:update_all]).to match_array([1, 1])
  end

  it 'does not rewrite a row that is already cleared' do
    create_merge_request(cached_markdown_version: nil, title_html: nil, description_html: nil)

    operation_run = operation
    operation_run.perform

    expect(operation_run.batch_metrics.affected_rows[:update_all]).to eq([0])
  end

  it 'converges after a first pass, leaving nothing to rewrite', :aggregate_failures do
    create_merge_request(cached_markdown_version: target_version - 1)
    create_merge_request(cached_markdown_version: target_version)

    first_pass = operation
    first_pass.perform

    second_pass = operation
    second_pass.perform

    expect(first_pass.batch_metrics.affected_rows[:update_all].sum).to eq(1)
    expect(second_pass.batch_metrics.affected_rows[:update_all].sum).to eq(0)
  end

  private

  def create_merge_request(cached_markdown_version:, title_html: '<p>title</p>', description_html: '<p>body</p>')
    merge_requests.create!(
      target_project_id: project.id,
      source_branch: 'feature',
      target_branch: 'master',
      title: 'MR',
      description: 'body',
      title_html: title_html,
      description_html: description_html,
      cached_markdown_version: cached_markdown_version
    )
  end
end
