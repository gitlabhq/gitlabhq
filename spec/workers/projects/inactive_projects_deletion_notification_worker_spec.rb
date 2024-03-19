# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::InactiveProjectsDeletionNotificationWorker, feature_category: :groups_and_projects do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:deletion_date) { Date.current }
    let_it_be(:non_existing_project_id) { non_existing_record_id }
    let_it_be(:project) { create(:project) }

    it 'invokes NotificationService and calls inactive_project_deletion_warning' do
      expect_next_instance_of(NotificationService) do |notification|
        expect(notification).to receive(:inactive_project_deletion_warning).with(project, deletion_date)
      end

      worker.perform(project.id, deletion_date)
    end

    it 'adds the project_id to redis key that tracks the deletion warning emails' do
      worker.perform(project.id, deletion_date)

      Gitlab::Redis::SharedState.with do |redis|
        expect(
          redis.hget('inactive_projects_deletion_warning_email_notified', "project:#{project.id}")
        ).to eq(Date.current.to_s)
      end
    end

    it 'rescues and logs the exception if project does not exist' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception)
        .with(instance_of(ActiveRecord::RecordNotFound), { project_id: non_existing_project_id })

      worker.perform(non_existing_project_id, deletion_date)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id, deletion_date] }
    end
  end
end
