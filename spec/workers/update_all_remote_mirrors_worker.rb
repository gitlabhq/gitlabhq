require 'rails_helper'

describe UpdateAllRemoteMirrorsWorker do
  describe "#perform" do

    let!(:mirror1) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:mirror2) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:mirror3) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }
    let!(:mirror4) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }

    it 'fails stuck mirrors' do
      worker = described_class.new

      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    describe 'update times' do
      after do
        Timecop.return
      end

      describe 'fifteen' do
        before do
          time = DateTime.now.beginning_of_hour + 15.minutes

          Timecop.freeze(time)
          mirror4.remote_mirrors.first.update_attributes(last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
        end

        it 'enqueues a job on mirrored Projects' do
          mirrors = [mirror1, mirror4]
          worker = described_class.new

          mirrors.each do |mirror|
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(mirror.id)
          end

          worker.perform
        end
      end

      describe "hourly" do
        before do
          time = DateTime.now.beginning_of_hour

          Timecop.freeze(time)
          mirror4.remote_mirrors.first.update_attributes(last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
        end

        it 'enqueues a job on mirrored Projects' do
          mirrors = [mirror1, mirror2, mirror4]
          worker = described_class.new

          mirrors.each do |mirror|
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(mirror.id)
          end

          worker.perform
        end
      end

      describe "daily" do
        before do
          time = DateTime.now.beginning_of_day

          Timecop.freeze(time)
          mirror4.remote_mirrors.first.update_attributes(last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
        end

        it 'enqueues a job on mirrored Projects' do
          mirrors = [mirror1, mirror2, mirror3, mirror4]
          worker = described_class.new

          mirrors.each do |mirror|
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(mirror.id)
          end

          worker.perform
        end
      end
    end
  end
end
