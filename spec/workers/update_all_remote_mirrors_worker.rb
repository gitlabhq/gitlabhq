require 'rails_helper'

describe UpdateAllRemoteMirrorsWorker do
  describe "#perform" do
    project_count_with_time = { DateTime.now.beginning_of_hour + 15.minutes => 2,
                                DateTime.now.beginning_of_hour => 3,
                                DateTime.now.beginning_of_day => 4
                              }

    let!(:mirror1) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:mirror2) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:mirror3) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }

    it 'fails stuck mirrors' do
      worker = described_class.new

      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    project_count_with_time.each do |time, project_count|
      describe "at #{time}" do
        let!(:mirror4) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAILY) }
        let(:mirrors) { RemoteMirror.where("last_successful_update_at + #{Gitlab::Database.minute_interval('sync_time')} <= ? OR sync_time IN (?)", time, Gitlab::Mirror.sync_times) }

        before do
          Timecop.freeze(time)
          mirror4.remote_mirrors.first.update_attributes(last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
        end

        it 'enqueues a job on mirrored Projects' do
          worker = described_class.new

          expect(mirrors.count).to eq(project_count)
          mirrors.each do |mirror|
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(mirror.id)
          end

          worker.perform
        end
      end
    end
  end
end
