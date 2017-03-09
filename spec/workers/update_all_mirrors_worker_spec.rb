require 'rails_helper'

describe UpdateAllMirrorsWorker do
  subject(:worker) { described_class.new }

  before { allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true) }

  describe '#perform' do
    let!(:fifteen_mirror)  { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::FIFTEEN) }
    let!(:hourly_mirror)   { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::HOURLY) }
    let!(:three_mirror)    { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::THREE) }
    let!(:six_mirror)      { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::SIX) }
    let!(:twelve_mirror)   { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::TWELVE) }
    let!(:daily_mirror)    { create(:empty_project, :mirror, sync_time: Gitlab::Mirror::DAILY) }
    let!(:outdated_mirror) { create(:empty_project, :mirror) }

    it 'fails stuck mirrors' do
      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    it 'does not execute if cannot get the lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)

      create(:empty_project, :mirror)

      expect(worker).not_to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    describe 'sync_time' do
      def expect_worker_to_enqueue_mirrors(mirrors)
        mirrors.each do |mirror|
          expect(worker).to receive(:rand).with((mirror.sync_time / 2).minutes).and_return(mirror.sync_time / 2)
          expect(RepositoryUpdateMirrorDispatchWorker).to receive(:perform_in).with(mirror.sync_time / 2, mirror.id)
        end

        worker.perform
      end

      before do
        time = DateTime.now.change(time_params)

        Timecop.freeze(time)
        outdated_mirror.update_attributes(mirror_last_successful_update_at: time - (Gitlab::Mirror::DAILY + 5).minutes)
      end

      describe 'fifteen' do
        let!(:time_params) { { hour: 1, min: 15 } }
        let(:mirrors) { [fifteen_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe 'hourly' do
        let!(:time_params) { { hour: 1 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe 'three' do
        let!(:time_params) { { hour: 3 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe 'six' do
        let!(:time_params) { { hour: 6 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, six_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe 'twelve' do
        let!(:time_params) { { hour: 12 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, six_mirror, twelve_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      describe 'daily' do
        let!(:time_params) { { hour: 0 } }
        let(:mirrors) { [fifteen_mirror, hourly_mirror, three_mirror, six_mirror, twelve_mirror, daily_mirror, outdated_mirror] }

        it { expect_worker_to_enqueue_mirrors(mirrors) }
      end

      after { Timecop.return }
    end
  end

  describe '#fail_stuck_mirrors!' do
    delegate :fail_stuck_mirrors!, to: :worker

    it 'ignores records that are not mirrors' do
      create(:empty_project, :import_started, mirror_last_update_at: 12.hours.ago)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      fail_stuck_mirrors!
    end

    it 'ignores records without in-progress import' do
      create(:empty_project, :mirror, :import_finished, mirror_last_update_at: 12.hours.ago)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      fail_stuck_mirrors!
    end

    it 'ignores records with recently updated mirrors' do
      create(:empty_project, :mirror, mirror_last_update_at: Time.now)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      fail_stuck_mirrors!
    end

    it 'transitions stuck mirrors to a failed state' do
      project = create(:empty_project, :mirror, mirror_last_update_at: 12.hours.ago)

      fail_stuck_mirrors!
      project.reload

      expect(project).to be_import_failed
    end

    it 'updates the import_error message' do
      project = create(:empty_project, :mirror, mirror_last_update_at: 12.hours.ago)

      fail_stuck_mirrors!
      project.reload

      expect(project.import_error).to eq 'The mirror update took too long to complete.'
    end
  end
end
