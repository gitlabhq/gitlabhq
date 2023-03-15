# frozen_string_literal: true

require "spec_helper"

RSpec.describe Issues::CloseWorker, feature_category: :team_planning do
  describe "#perform" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:issue) { create(:issue, project: project, author: user) }

    let(:commit) { project.commit }
    let(:opts) do
      { "closed_by" => user&.id, "commit_hash" => commit.to_hash }
    end

    subject(:worker) { described_class.new }

    describe "#perform" do
      context "when the user can update the issues" do
        it "closes the issues" do
          worker.perform(project.id, issue.id, issue.class.to_s, opts)

          issue.reload

          expect(issue.closed?).to eq(true)
        end

        it "closes external issues" do
          external_issue = ExternalIssue.new("foo", project)
          closer = instance_double(Issues::CloseService, execute: true)

          expect(Issues::CloseService).to receive(:new).with(container: project, current_user: user).and_return(closer)
          expect(closer).to receive(:execute).with(external_issue, commit: commit)

          worker.perform(project.id, external_issue.id, external_issue.class.to_s, opts)
        end
      end

      context "when the user can not update the issues" do
        it "does not close the issues" do
          other_user = create(:user)
          opts = { "closed_by" => other_user.id, "commit_hash" => commit.to_hash }

          worker.perform(project.id, issue.id, issue.class.to_s, opts)

          issue.reload

          expect(issue.closed?).to eq(false)
        end
      end
    end

    shared_examples "when object does not exist" do
      it "does not call the close issue service" do
        expect(Issues::CloseService).not_to receive(:new)

        expect { worker.perform(project.id, issue.id, issue.class.to_s, opts) }
          .not_to raise_exception
      end
    end

    context "when the project does not exist" do
      before do
        allow(Project).to receive(:find_by_id).with(project.id).and_return(nil)
      end

      it_behaves_like "when object does not exist"
    end

    context "when the user does not exist" do
      before do
        allow(User).to receive(:find_by_id).with(user.id).and_return(nil)
      end

      it_behaves_like "when object does not exist"
    end

    context "when the issue does not exist" do
      before do
        allow(Issue).to receive(:find_by_id).with(issue.id).and_return(nil)
      end

      it_behaves_like "when object does not exist"
    end
  end
end
