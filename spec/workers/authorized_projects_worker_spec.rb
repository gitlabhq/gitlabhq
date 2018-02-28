require 'spec_helper'

describe AuthorizedProjectsWorker do
  let(:project) { create(:project) }

  describe '.bulk_perform_and_wait' do
    it 'schedules the ids and waits for the jobs to complete' do
      project.owner.project_authorizations.delete_all

      described_class.bulk_perform_and_wait([[project.owner.id]])

      expect(project.owner.project_authorizations.count).to eq(1)
    end
  end

  describe '.bulk_perform_async' do
    it "uses it's respective sidekiq queue" do
      args = [[project.owner.id]]
      push_bulk_args = {
        'class' => described_class,
        'queue' => described_class.sidekiq_options['queue'],
        'args' => args
      }

      expect(Sidekiq::Client).to receive(:push_bulk).with(push_bulk_args).once

      described_class.bulk_perform_async(args)
    end
  end

  describe '#perform' do
    subject { described_class.new }

    it "refreshes user's authorized projects" do
      user = create(:user)

      expect_any_instance_of(User).to receive(:refresh_authorized_projects)

      subject.perform(user.id)
    end

    context "when the user is not found" do
      it "does nothing" do
        expect_any_instance_of(User).not_to receive(:refresh_authorized_projects)

        subject.perform(-1)
      end
    end
  end
end
