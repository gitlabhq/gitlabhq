# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::ClearPersistentRefService, :use_clean_rails_memory_store_caching, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let!(:pipeline) { create(:ci_pipeline, :success, project: project) }

  subject(:service) { described_class.new(pipeline) }

  before do
    Rails.cache.write(service.send(:pipeline_persistent_ref_cache_key), true)
  end

  it 'deletes a persistent ref asynchronously' do
    expect(pipeline.persistent_ref).to receive(:async_delete)
    expect(pipeline.persistent_ref).not_to receive(:delete)

    expect { service.execute }
      .to change { Rails.cache.read(service.send(:pipeline_persistent_ref_cache_key)) }.from(true).to(nil)
  end

  context 'when pipeline_delete_gitaly_refs_in_batches is disabled' do
    before do
      stub_feature_flags(pipeline_delete_gitaly_refs_in_batches: false)
    end

    it 'deletes a persistent ref asynchronously via ::Ci::PipelineCleanupRefWorker', :sidekiq_inline do
      expect(pipeline.persistent_ref).not_to receive(:delete_refs)

      expect(Ci::PipelineCleanupRefWorker).to receive(:perform_async)
        .with(pipeline.id).and_call_original

      expect_next_instance_of(Ci::PersistentRef) do |persistent_ref|
        expect(persistent_ref).to receive(:delete_refs)
          .with("refs/#{Repository::REF_PIPELINES}/#{pipeline.id}").once
      end

      expect { service.execute }
        .to change { Rails.cache.read(service.send(:pipeline_persistent_ref_cache_key)) }.from(true).to(nil)
    end

    context 'when pipeline_cleanup_ref_worker_async is disabled' do
      before do
        stub_feature_flags(pipeline_delete_gitaly_refs_in_batches: false)
        stub_feature_flags(pipeline_cleanup_ref_worker_async: false)
      end

      it 'deletes a persistent ref synchronously' do
        expect(Ci::PipelineCleanupRefWorker).not_to receive(:perform_async).with(pipeline.id)

        expect(pipeline.persistent_ref).to receive(:delete_refs).once
          .with("refs/#{Repository::REF_PIPELINES}/#{pipeline.id}")

        expect { service.execute }
          .to change { Rails.cache.read(service.send(:pipeline_persistent_ref_cache_key)) }.from(true).to(nil)
      end
    end
  end
end
