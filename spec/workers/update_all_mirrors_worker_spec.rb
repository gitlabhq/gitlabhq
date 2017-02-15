require 'rails_helper'

describe UpdateAllMirrorsWorker do
  before { allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true) }

  describe '#perform' do
    let(:worker) { described_class.new }
    let!(:mirror1) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:mirror2) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:mirror3) { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::DAILY) }
    let!(:mirror4) { create(:empty_project, :mirror) }

    it 'fails stuck mirrors' do
      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    describe 'sync_time' do
      def expect_worker_to_update_mirrors(mirrors)
        mirrors.each do |mirror|
          expect(worker).to receive(:rand).with((mirror.sync_time / 2).minutes).and_return(mirror.sync_time / 2)
          expect(RepositoryUpdateMirrorDispatchWorker).to receive(:perform_in).with(mirror.sync_time / 2, mirror.id)
        end
      end

      def setup(time)
        Timecop.freeze(time)
        mirror4.update_attributes(mirror_last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
      end

      describe 'fifteen' do
        let(:mirrors) { [mirror1, mirror4] }

        before { setup(DateTime.now.beginning_of_hour + 15.minutes) }

        it 'enqueues a job on mirrored projects' do
          expect_worker_to_update_mirrors(mirrors)

          worker.perform
        end
      end

      describe 'hourly' do
        let(:mirrors) { [mirror1, mirror2, mirror4] }

        before { setup(DateTime.now.beginning_of_hour) }

        it 'enqueues a job on mirrored projects' do
          expect_worker_to_update_mirrors(mirrors)

          worker.perform
        end
      end

      describe 'daily' do
        let(:mirrors) { [mirror1, mirror2, mirror3, mirror4] }

        before { setup(DateTime.now.beginning_of_day) }

        it 'enqueues a job on mirrored projects' do
          expect_worker_to_update_mirrors(mirrors)

          worker.perform
        end
      end

      after { Timecop.return }
    end

    it 'does not execute if cannot get the lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)

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
