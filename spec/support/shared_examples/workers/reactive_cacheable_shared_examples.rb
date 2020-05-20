# frozen_string_literal: true

RSpec.shared_examples 'reactive cacheable worker' do
  describe '#perform' do
    context 'when reactive cache worker class is found' do
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

    context 'when reactive cache worker class is not found' do
      it 'raises no error' do
        expect { described_class.new.perform("Environment", -1) }.not_to raise_error
      end
    end

    context 'when reactive cache worker class is invalid' do
      it 'raises no error' do
        expect { described_class.new.perform("FooBarKux", -1) }.not_to raise_error
      end
    end
  end

  describe 'worker context' do
    it 'sets the related class on the job' do
      described_class.perform_async('Environment', 1, 'other', 'argument')

      scheduled_job = described_class.jobs.first

      expect(scheduled_job).to include('meta.related_class' => 'Environment')
    end

    it 'sets the related class on the job when it was passed as a class' do
      described_class.perform_async(Project, 1, 'other', 'argument')

      scheduled_job = described_class.jobs.first

      expect(scheduled_job).to include('meta.related_class' => 'Project')
    end
  end
end
