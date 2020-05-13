# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "refreshes user's project authorizations" do
  describe '#perform' do
    let(:user) { create(:user) }

    subject(:job) { described_class.new }

    it "refreshes user's authorized projects" do
      expect_any_instance_of(User).to receive(:refresh_authorized_projects)

      job.perform(user.id)
    end

    context "when the user is not found" do
      it "does nothing" do
        expect_any_instance_of(User).not_to receive(:refresh_authorized_projects)

        job.perform(-1)
      end
    end

    it_behaves_like "an idempotent worker" do
      let(:job_args) { user.id }

      it "does not change authorizations when run twice" do
        group = create(:group)
        create(:project, namespace: group)
        group.add_developer(user)

        # Delete the authorization created by the after save hook of the member
        # created above.
        user.project_authorizations.delete_all

        expect { job.perform(user.id) }.to change { user.project_authorizations.reload.size }.by(1)
        expect { job.perform(user.id) }.not_to change { user.project_authorizations.reload.size }
      end
    end
  end
end
