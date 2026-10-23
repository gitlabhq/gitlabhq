# frozen_string_literal: true

RSpec.shared_examples 'a GET that leaves stale markdown caches to the refresh worker' do
  let(:analyzer) { Gitlab::Database::QueryAnalyzers::PreventWritesOnGet }

  before do
    stub_feature_flags(detect_writes_on_get: true)
    stale_note.update_columns(cached_markdown_version: nil)
  end

  it 'does not write to the database' do
    expect(analyzer::Logger).not_to receive(:warn)

    perform_get

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'enqueues the cache refresh without persisting it' do
    expect(Gitlab::MarkdownCache::RefreshWorker)
      .to receive(:perform_async).with(stale_note.class.name, stale_note.id).at_least(:once)

    perform_get

    expect(stale_note.reload.cached_markdown_version).to be_nil
  end
end
