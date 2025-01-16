# frozen_string_literal: true

require "spec_helper"

RSpec.describe Issues::CloseWorker, feature_category: :team_planning do
  describe "#perform" do
    let_it_be(:developer) { create(:user) }
    let_it_be(:author) { create(:user) }
    let_it_be(:project) { create(:project, :public, :repository, developers: [developer]) }
    let_it_be_with_reload(:issue) { create(:issue, project: project, author: author) }

    let(:project_id) { project.id }
    let(:issue_id) { issue.id }
    let(:current_user_id) { developer&.id }
    let(:current_author_id) { author&.id }
    let(:commit) { project.commit }
    let(:opts) do
      { "closed_by" => current_author_id, "user_id" => current_user_id, "commit_hash" => commit.to_hash }
    end

    subject(:perform_job) { described_class.new.perform(project_id, issue_id, issue.class.to_s, opts) }

    describe "#perform" do
      context "when the user can update the issues" do
        it "closes the issues" do
          perform_job

          issue.reload

          expect(issue).to be_closed
        end

        it "closes external issues" do
          external_issue = ExternalIssue.new("foo", project)
          closer = instance_double(Issues::CloseService, execute: true)

          expect(Issues::CloseService).to receive(:new).with(container: project, current_user: author)
                                                       .and_return(closer)
          expect(closer).to receive(:execute).with(external_issue, commit: commit)

          described_class.new.perform(project.id, external_issue.id, external_issue.class.to_s, opts)
        end
      end

      context "when the user can not update the issues" do
        let(:current_user_id) { create(:user).id }

        it 'does not close the issue' do
          perform_job

          issue.reload

          expect(issue).not_to be_closed
        end
      end

      context "when user is not provided to the worker" do
        let(:current_user_id) { nil }

        it 'does not close the issue' do
          perform_job

          issue.reload

          expect(issue).not_to be_closed
        end
      end
    end

    shared_examples "when object does not exist" do
      it "does not call the close issue service" do
        expect(Issues::CloseService).not_to receive(:new)

        expect { perform_job }.not_to raise_exception
      end
    end

    context "when the project does not exist" do
      let(:project_id) { non_existing_record_id }

      it_behaves_like "when object does not exist"
    end

    context "when the author does not exist" do
      let(:current_author_id) { non_existing_record_id }

      it_behaves_like "when object does not exist"
    end

    context "when the issue does not exist" do
      let(:issue_id) { non_existing_record_id }

      it_behaves_like "when object does not exist"
    end
  end
end
