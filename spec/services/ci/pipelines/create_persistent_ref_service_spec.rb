# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::CreatePersistentRefService, :use_clean_rails_memory_store_caching, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let!(:pipeline) { create(:ci_pipeline, project: project) }

  subject(:service) { described_class.new(pipeline) }

  it 'creates persistent ref and caches true' do
    expect { service.execute }
      .to change { pipeline.persistent_ref.exist? }.from(false).to(true)
      .and change { Rails.cache.read(service.send(:pipeline_persistent_ref_cache_key)) }.from(nil).to(true)
      .and not_change { pipeline.status }
  end

  context 'when persistent ref is already created' do
    before do
      pipeline.persistent_ref.create # rubocop:disable Rails/SaveBang -- not ActiveRecord
    end

    it 'does not create persistent ref and caches true' do
      expect { service.execute }
        .to not_change { pipeline.persistent_ref.exist? }.from(true)
        .and change { Rails.cache.read(service.send(:pipeline_persistent_ref_cache_key)) }.from(nil).to(true)
        .and not_change { pipeline.status }
    end
  end

  context 'when persistent ref creation raises error' do
    it 'drops the pipeline and caches false' do
      expect(pipeline.persistent_ref).to receive(:create_ref).and_raise('Error')
      expect { service.execute }
        .to not_change { pipeline.persistent_ref.exist? }.from(false)
        .and change { Rails.cache.read(service.send(:pipeline_persistent_ref_cache_key)) }.from(nil).to(false)
        .and change { pipeline.status }.to('failed')
    end
  end

  context 'when ff ci_only_one_persistent_ref_creation is disabled' do
    before do
      stub_feature_flags(ci_only_one_persistent_ref_creation: false)
    end

    it 'creates persistent ref' do
      expect { service.execute }
        .to change { pipeline.persistent_ref.exist? }.from(false).to(true)
        .and not_change { pipeline.status }

      expect(pipeline.persistent_ref).to receive(:exist?).and_call_original
      expect(pipeline.persistent_ref).not_to receive(:create)
      service.execute
    end

    context 'when persistent ref is already created' do
      before do
        pipeline.persistent_ref.create # rubocop:disable Rails/SaveBang -- not ActiveRecord
      end

      it 'does not create persistent ref and caches true' do
        expect { service.execute }
          .to not_change { pipeline.persistent_ref.exist? }.from(true)
          .and not_change { pipeline.status }

        expect(pipeline.persistent_ref).to receive(:exist?).and_call_original
        expect(pipeline.persistent_ref).not_to receive(:create)
        service.execute
      end
    end

    context 'when persistent ref creation raises error' do
      it 'drops the pipeline and caches false' do
        expect(pipeline.persistent_ref).to receive(:create_ref).and_raise('Error')
        expect { service.execute }
          .to not_change { pipeline.persistent_ref.exist? }.from(false)
          .and not_change { pipeline.status }

        expect(pipeline.persistent_ref).to receive(:exist?).and_call_original
        expect(pipeline.persistent_ref).to receive(:create)
        service.execute
      end
    end
  end
end
