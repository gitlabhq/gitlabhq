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
    end
  end
end
