# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InactiveProjectsDeletionWarningTracker do
  let_it_be(:project_id) { 1 }

  describe '.notified_projects', :clean_gitlab_redis_shared_state do
    before do
      freeze_time do
        Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
      end
    end

    it 'returns the list of projects for which deletion warning email has been sent' do
      expected_hash = { "project:1" => "#{Date.current}" }

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
