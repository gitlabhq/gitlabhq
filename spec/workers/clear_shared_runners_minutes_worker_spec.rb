require 'spec_helper'

describe ClearSharedRunnersMinutesWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      expect_any_instance_of(described_class)
        .to receive(:try_obtain_lease).and_return(true)
    end

    subject { worker.perform }

    context 'when project statistics are defined' do
      let(:project) { create(:empty_project) }
      let(:statistics) { project.statistics }

      before do
        statistics.update(shared_runners_seconds: 100)
      end

      it 'clears counters' do
        subject

        expect(statistics.reload.shared_runners_seconds).to be_zero
      end

      it 'resets timer' do
        subject

        expect(statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.now)
      end
    end

    context 'when namespace statistics are defined' do
      let!(:statistics) { create(:namespace_statistics, shared_runners_seconds: 100) }

      it 'clears counters' do
        subject

        expect(statistics.reload.shared_runners_seconds).to be_zero
      end

      it 'resets timer' do
        subject

        expect(statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.now)
      end
    end
  end
end
