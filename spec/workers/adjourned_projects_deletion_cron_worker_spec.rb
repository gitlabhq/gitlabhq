# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdjournedProjectsDeletionCronWorker, feature_category: :compliance_management do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:deletion_adjourned_period_days) { 10 }
    let_it_be(:user) { create(:user) }
    let_it_be(:marked_for_deletion_at) { (deletion_adjourned_period_days + 1).days.ago }

    let!(:project_marked_for_deletion) do
      create(:project, marked_for_deletion_at: marked_for_deletion_at, deleting_user: user)
    end

    before do
      stub_application_setting(deletion_adjourned_period: deletion_adjourned_period_days)
      create(:project)
      create(:project, marked_for_deletion_at: (deletion_adjourned_period_days - 1).days.ago)
    end

    it 'only schedules to delete projects marked for deletion before number of days from settings' do
      expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(0, project_marked_for_deletion.id)

      worker.perform
    end

    context 'when two projects are scheduled for deletion' do
      let_it_be(:project_marked_for_deletion_two) do
        create(:project, marked_for_deletion_at: marked_for_deletion_at, deleting_user: user)
      end

      it 'schedules the second job 10 seconds after the first' do
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(10, project_marked_for_deletion.id)
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(0, project_marked_for_deletion_two.id)

        worker.perform
      end
    end

    context 'with marked for deletion exactly before number of days from settings' do
      let(:marked_for_deletion_at) { deletion_adjourned_period_days.days.ago }

      it 'schedules to delete project', :freeze_time do
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(0, project_marked_for_deletion.id)

        worker.perform
      end
    end
  end
end
