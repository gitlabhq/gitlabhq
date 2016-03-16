require 'rails_helper'

describe UpdateAllMirrorsWorker do
  describe '#perform' do
    it 'fails stuck mirrors' do
      worker = described_class.new

      expect(worker).to receive(:fail_stuck_mirrors!)

      worker.perform
    end

    it 'updates all mirrored Projects' do
      create(:empty_project, :mirror)
      create(:empty_project)

      expect_any_instance_of(Project).to receive(:update_mirror).once

      described_class.new.perform
    end
  end

  describe '#fail_stuck_mirrors!' do
    it 'ignores records that are not mirrors' do
      create(:empty_project, :import_started, mirror_last_update_at: 3.days.ago)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      perform
    end

    it 'ignores records without in-progress import' do
      create(:empty_project, :mirror, :import_finished, mirror_last_update_at: 3.days.ago)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      perform
    end

    it 'ignores records with recently updated mirrors' do
      create(:empty_project, :mirror, mirror_last_update_at: Time.now)

      expect_any_instance_of(Project).not_to receive(:import_fail)

      perform
    end

    it 'transitions stuck mirrors to a failed state' do
      project = create(:empty_project, :mirror, mirror_last_update_at: 3.days.ago)

      perform
      project.reload

      expect(project).to be_import_failed
    end

    it 'updates the import_error message' do
      project = create(:empty_project, :mirror, mirror_last_update_at: 3.days.ago)

      perform
      project.reload

      expect(project.import_error).to eq 'The mirror update took too long to complete.'
    end

    def perform
      described_class.new.fail_stuck_mirrors!
    end
  end
end
