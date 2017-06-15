require 'rails_helper'

describe UpdateAllMirrorsWorker do
  subject(:worker) { described_class.new }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  describe '#perform' do
    it 'fails stuck mirrors' do
      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    it 'does not execute if cannot get the lease' do
      create(:empty_project, :mirror)

      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)

      expect(worker).not_to receive(:fail_stuck_mirrors!)

      worker.perform
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

    it 'transitions stuck mirrors to a failed state and updates import_error message' do
      project = create(:empty_project, :mirror, :import_started)
      project.mirror_data.update_attributes(last_update_started_at: 25.minutes.ago)

      fail_stuck_mirrors!
      project.reload

      expect(project).to be_import_failed
      expect(project.reload.import_error).to eq 'The mirror update took too long to complete.'
    end
  end
end
