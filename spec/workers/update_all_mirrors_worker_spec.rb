require 'rails_helper'

describe UpdateAllMirrorsWorker do
  before do
    allow_any_instance_of(Gitlab::ExclusiveLease)
      .to receive(:try_obtain).and_return(true)
  end

  describe '#perform' do
    project_count_with_time = { DateTime.now.beginning_of_hour + 15.minutes => 2,
                                DateTime.now.beginning_of_hour => 3,
                                DateTime.now.beginning_of_day => 4
                              }

    let!(:mirror1) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:mirror2) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:mirror3) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::DAILY) }

    it 'fails stuck mirrors' do
      worker = described_class.new

      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    project_count_with_time.each do |time, project_count|
      describe "at #{time}" do
        let!(:mirror4) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::DAILY, mirror_last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes }
        let(:mirrors) { Project.mirror.where("mirror_last_successful_update_at + #{Gitlab::Database.minute_interval('sync_time')} <= ? OR sync_time IN (?)", time, Gitlab::Mirror.sync_times) }

        before do
          Timecop.freeze(time)
        end

        it 'enqueues a job on mirrored Projects' do
          worker = described_class.new

          expect(mirrors.count).to eq(project_count)
          mirrors.each do |mirror|
            expect(worker).to receive(:rand).with((mirror.sync_time / 2).minutes).and_return(mirror.sync_time / 2)
            expect(RepositoryUpdateMirrorDispatchWorker).to receive(:perform_in).with(mirror.sync_time / 2, mirror.id)
          end

          worker.perform
        end
      end
    end

    it 'does not execute if cannot get the lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(false)

      worker = described_class.new
      create(:empty_project, :mirror)

      expect(worker).not_to receive(:fail_stuck_mirrors!)

      worker.perform
    end
  end

  describe '#fail_stuck_mirrors!' do
    it 'ignores records that are not mirrors' do
      create(:empty_project, :import_started, mirror_last_update_at: 12.hours.ago)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      perform
    end

    it 'ignores records without in-progress import' do
      create(:empty_project, :mirror, :import_finished, mirror_last_update_at: 12.hours.ago)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      perform
    end

    it 'ignores records with recently updated mirrors' do
      create(:empty_project, :mirror, mirror_last_update_at: Time.now)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      perform
    end

    it 'transitions stuck mirrors to a failed state' do
      project = create(:empty_project, :mirror, mirror_last_update_at: 12.hours.ago)

      perform
      project.reload

      expect(project).to be_import_failed
    end

    it 'updates the import_error message' do
      project = create(:empty_project, :mirror, mirror_last_update_at: 12.hours.ago)

      perform
      project.reload

      expect(project.import_error).to eq 'The mirror update took too long to complete.'
    end

    def perform
      described_class.new.fail_stuck_mirrors!
    end
  end
end
