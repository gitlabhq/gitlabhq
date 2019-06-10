# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::BaseWorker do
  let(:subclass) do
    # Creating an anonymous class for a worker is complicated, as we generate the
    # queue name from the class name.
    Gitlab::PhabricatorImport::ImportTasksWorker
  end

  describe '.schedule' do
    let(:arguments) { %w[project_id the_next_page] }

    it 'schedules the job' do
      expect(subclass).to receive(:perform_async).with(*arguments)

      subclass.schedule(*arguments)
    end

    it 'counts the scheduled job', :clean_gitlab_redis_shared_state do
      state = Gitlab::PhabricatorImport::WorkerState.new('project_id')

      allow(subclass).to receive(:remove_job) # otherwise the job is removed before we saw it

      expect { subclass.schedule(*arguments) }.to change { state.running_count }.by(1)
    end
  end

  describe '#perform' do
    let(:project) { create(:project, :import_started, import_url: "https://a.phab.instance") }
    let(:worker) { subclass.new }
    let(:state) { Gitlab::PhabricatorImport::WorkerState.new(project.id) }

    before do
      allow(worker).to receive(:import)
    end

    it 'does not break for a non-existing project' do
      expect { worker.perform('not a thing') }.not_to raise_error
    end

    it 'does not do anything when the import is not in progress' do
      project = create(:project, :import_failed)

      expect(worker).not_to receive(:import)

      worker.perform(project.id)
    end

    it 'calls import for the project' do
      expect(worker).to receive(:import).with(project, 'other_arg')

      worker.perform(project.id, 'other_arg')
    end

    it 'marks the project as imported if there was only one job running' do
      worker.perform(project.id)

      expect(project.import_state.reload).to be_finished
    end

    it 'does not mark the job as finished when there are more scheduled jobs' do
      2.times { state.add_job }

      worker.perform(project.id)

      expect(project.import_state.reload).to be_in_progress
    end

    it 'decrements the job counter' do
      expect { worker.perform(project.id) }.to change { state.running_count }.by(-1)
    end
  end
end
