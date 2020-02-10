# frozen_string_literal: true

require 'spec_helper'

describe ReactiveCachingWorker do
  describe '#perform' do
    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:project) { cluster.project }
      let!(:environment) { create(:environment, project: project) }

      it 'calls #exclusively_update_reactive_cache!' do
        expect_any_instance_of(Environment).to receive(:exclusively_update_reactive_cache!)

        described_class.new.perform("Environment", environment.id)
      end

      context 'when ReactiveCaching::ExceededReactiveCacheLimit is raised' do
        it 'avoids failing the job and tracks via Gitlab::ErrorTracking' do
          allow_any_instance_of(Environment).to receive(:exclusively_update_reactive_cache!)
            .and_raise(ReactiveCaching::ExceededReactiveCacheLimit)

          expect(Gitlab::ErrorTracking).to receive(:track_exception)
            .with(kind_of(ReactiveCaching::ExceededReactiveCacheLimit))

          described_class.new.perform("Environment", environment.id)
        end
      end
    end
  end
end
