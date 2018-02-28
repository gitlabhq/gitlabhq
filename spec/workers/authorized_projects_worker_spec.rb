require 'spec_helper'

describe AuthorizedProjectsWorker do
  let(:project) { create(:project) }

  def build_args_list(*ids, multiply: 1)
    args_list = ids.map { |id| [id] }
    args_list * multiply
  end

  describe '.bulk_perform_and_wait' do
    it 'schedules the ids and waits for the jobs to complete' do
      args_list = build_args_list(project.owner.id)

      project.owner.project_authorizations.delete_all
      described_class.bulk_perform_and_wait(args_list)

      expect(project.owner.project_authorizations.count).to eq(1)
    end

    it 'inlines workloads <= 3 jobs' do
      args_list = build_args_list(project.owner.id, multiply: 3)
      expect(described_class).to receive(:bulk_perform_inline).with(args_list)

      described_class.bulk_perform_and_wait(args_list)
    end

    it 'runs > 3 jobs using sidekiq' do
      project.owner.project_authorizations.delete_all

      expect(described_class).to receive(:bulk_perform_async).and_call_original

      args_list = build_args_list(project.owner.id, multiply: 4)
      described_class.bulk_perform_and_wait(args_list)

      expect(project.owner.project_authorizations.count).to eq(1)
    end
  end

  describe '.bulk_perform_inline' do
    it 'refreshes the authorizations inline' do
      project.owner.project_authorizations.delete_all

      expect_any_instance_of(described_class).to receive(:perform).and_call_original

      described_class.bulk_perform_inline(build_args_list(project.owner.id))

      expect(project.owner.project_authorizations.count).to eq(1)
    end

    it 'enqueues jobs if an error is raised' do
      invalid_id = -1
      args_list = build_args_list(project.owner.id, invalid_id)

      allow_any_instance_of(described_class).to receive(:perform).with(project.owner.id)
      allow_any_instance_of(described_class).to receive(:perform).with(invalid_id).and_raise(ArgumentError)
      expect(described_class).to receive(:bulk_perform_async).with(build_args_list(invalid_id))

      described_class.bulk_perform_inline(args_list)
    end
  end

  describe '.bulk_perform_async' do
    it "uses it's respective sidekiq queue" do
      args_list = build_args_list(project.owner.id)
      push_bulk_args = {
        'class' => described_class,
        'queue' => described_class.sidekiq_options['queue'],
        'args' => args_list
      }

      expect(Sidekiq::Client).to receive(:push_bulk).with(push_bulk_args).once

      described_class.bulk_perform_async(args_list)
    end
  end

  describe '#perform' do
    let(:user) { create(:user) }

    subject(:job) { described_class.new }

    it "refreshes user's authorized projects" do
      expect_any_instance_of(User).to receive(:refresh_authorized_projects)

      job.perform(user.id)
    end

    it 'notifies the JobWaiter when done if the key is provided' do
      expect(Gitlab::JobWaiter).to receive(:notify).with('notify-key', job.jid)

      job.perform(user.id, 'notify-key')
    end

    context "when the user is not found" do
      it "does nothing" do
        expect_any_instance_of(User).not_to receive(:refresh_authorized_projects)

        job.perform(-1)
      end
    end
  end
end
