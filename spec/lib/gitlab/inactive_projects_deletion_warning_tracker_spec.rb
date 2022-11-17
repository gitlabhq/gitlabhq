# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InactiveProjectsDeletionWarningTracker, :freeze_time do
  let_it_be(:project_id) { 1 }

  describe '.notified_projects', :clean_gitlab_redis_shared_state do
    before do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
    end

    it 'returns the list of projects for which deletion warning email has been sent' do
      expected_hash = { "project:1" => Date.current.to_s }

      expect(Gitlab::InactiveProjectsDeletionWarningTracker.notified_projects).to eq(expected_hash)
    end
  end

  describe '.reset_all' do
    before do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
    end

    it 'deletes all the projects for which deletion warning email was sent' do
      Gitlab::InactiveProjectsDeletionWarningTracker.reset_all

      expect(Gitlab::InactiveProjectsDeletionWarningTracker.notified_projects).to eq({})
    end
  end

  describe '#notified?' do
    before do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
    end

    it 'returns true if the project has already been notified' do
      expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).notified?).to eq(true)
    end

    it 'returns false if the project has not been notified' do
      expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(2).notified?).to eq(false)
    end
  end

  describe '#mark_notified' do
    it 'marks the project as being notified' do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified

      expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).notified?).to eq(true)
    end
  end

  describe '#notification_date', :clean_gitlab_redis_shared_state do
    before do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
    end

    it 'returns the date if a deletion warning email has been sent for a given project' do
      expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).notification_date).to eq(Date.current.to_s)
    end

    it 'returns nil if a deletion warning email has not been sent for a given project' do
      expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(2).notification_date).to eq(nil)
    end
  end

  describe '#scheduled_deletion_date', :clean_gitlab_redis_shared_state do
    shared_examples 'returns the expected deletion date' do
      it do
        expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).scheduled_deletion_date)
          .to eq(1.month.from_now.to_date.to_s)
      end
    end

    before do
      stub_application_setting(inactive_projects_delete_after_months: 2)
      stub_application_setting(inactive_projects_send_warning_email_after_months: 1)
    end

    context 'without a stored deletion email date' do
      it_behaves_like 'returns the expected deletion date'
    end

    context 'with a stored deletion email date' do
      before do
        Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
      end

      it_behaves_like 'returns the expected deletion date'
    end
  end

  describe '#reset' do
    before do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
    end

    it 'resets the project as not being notified' do
      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).reset

      expect(Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).notified?).to eq(false)
    end
  end
end
