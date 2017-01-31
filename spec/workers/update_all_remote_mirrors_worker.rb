require 'rails_helper'

describe UpdateAllRemoteMirrorsWorker do
  describe "#perform" do
    PROJECT_COUNT_WITH_TIME = { DateTime.now.beginning_of_hour + 15.minutes => 1,
                                DateTime.now.beginning_of_hour => 2,
                                DateTime.now.beginning_of_day => 3
                              }

    let!(:mirror1) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:mirror2) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:mirror3) { create(:project, :remote_mirror, sync_time: Gitlab::Mirror::DAYLY) }
    let(:mirrors) { RemoteMirror.where(sync_time: Gitlab::Mirror.sync_times) }

    it 'fails stuck mirrors' do
      worker = described_class.new

      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    PROJECT_COUNT_WITH_TIME.each do |time, project_count|
      describe "at #{time}" do
        before do
          allow(DateTime).to receive(:now).and_return(time)
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
