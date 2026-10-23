# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache::ExternalStorage::Extension, feature_category: :markdown do
  describe '#refresh_stale_markdown_cache' do
    let(:version_class) { Ci::Catalog::BundledResources::Version }

    let(:version) do
      created = create(:ci_catalog_bundled_resource_version, readme: '**bold**')
      created.update_columns(cached_markdown_version: nil)

      version_class.find(created.id)
    end

    before do
      stub_feature_flags(markdown_cache_async_refresh: true)
    end

    it 'persists the HTML inline without enqueueing the worker' do
      expect(Gitlab::MarkdownCache::RefreshWorker).not_to receive(:perform_async)

      version.refresh_stale_markdown_cache

      expect(version_class.find(version.id).cached_markdown_version)
        .to eq(Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_SHIFTED)
    end
  end
end
