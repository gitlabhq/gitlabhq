require 'rails_helper'

describe UpdateAllRemoteMirrorsWorker do
  let(:worker) { described_class.new }

  describe "#perform" do
    let!(:mirror1) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:mirror2) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:mirror3) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }
    let!(:mirror4) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }

    it 'fails stuck mirrors' do
      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    describe 'sync time' do
      def expect_worker_to_update_mirrors(mirrors)
        mirrors.each do |mirror|
          expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(mirror.id)
        end
      end

      def setup(time)
        Timecop.freeze(time)
        mirror4.remote_mirrors.first.update_attributes(last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
      end

      describe 'fifteen' do
        let(:mirrors) { [mirror1, mirror4] }

        before { setup(DateTime.now.beginning_of_hour + 15.minutes) }

        it 'enqueues a job on remote mirrored projects' do
          expect_worker_to_update_mirrors(mirrors)

          worker.perform
        end
      end

      describe "hourly" do
        let(:mirrors) { [mirror1, mirror2, mirror4] }

        before { setup(DateTime.now.beginning_of_hour) }

        it 'enqueues a job on remote mirrored projects' do
          expect_worker_to_update_mirrors(mirrors)

          worker.perform
        end
      end

      describe "daily" do
        let(:mirrors) { [mirror1, mirror2, mirror3, mirror4] }

        before { setup(DateTime.now.beginning_of_day) }

        it 'enqueues a job on remote mirrored projects' do
          expect_worker_to_update_mirrors(mirrors)

          worker.perform
        end
      end

      after { Timecop.return }
    end
  end
end
