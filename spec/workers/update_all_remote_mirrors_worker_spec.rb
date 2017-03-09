require 'rails_helper'

describe UpdateAllRemoteMirrorsWorker do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let!(:fifteen_mirror) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:hourly_mirror) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:three_mirror) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::THREE) }
    let!(:six_mirror) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::SIX) }
    let!(:twelve_mirror) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::TWELVE) }
    let!(:daily_mirror) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }
    let!(:outdated_mirror) { create(:project, :remote_mirror) }

    it 'fails stuck mirrors' do
      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    describe 'sync time' do
      def expect_worker_to_enqueue_mirrors(mirrors)
        mirrors.each do |mirror|
          expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(mirror.id)
        end

        worker.perform
      end

      before do
        time = DateTime.now.change(time_params)

        Timecop.freeze(time)
        outdated_mirror.remote_mirrors.first.update_attributes(last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
      end

      describe 'fifteen' do
        let!(:time_params) { { hour: 1, min: 15 } }
        let(:mirrors) { [fifteen_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe "hourly" do
        let!(:time_params) { { hour: 1 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe "three" do
        let!(:time_params) { { hour: 3 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe "six" do
        let!(:time_params) { { hour: 6 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, six_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe "twelve" do
        let!(:time_params) { { hour: 12 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, six_mirror, twelve_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe "daily" do
        let!(:time_params) { { hour: 0 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, six_mirror, twelve_mirror, daily_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      after { Timecop.return }
    end
  end
end
