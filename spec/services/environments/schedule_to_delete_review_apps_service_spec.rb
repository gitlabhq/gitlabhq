# frozen_string_literal: true

require "spec_helper"

RSpec.describe Environments::ScheduleToDeleteReviewAppsService do
  include ExclusiveLeaseHelpers

  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer)  { create(:user) }
  let_it_be(:reporter)   { create(:user) }
  let_it_be(:project)    { create(:project, :private, :repository, namespace: maintainer.namespace) }

  let(:service)      { described_class.new(project, current_user, before: 30.days.ago, dry_run: dry_run) }
  let(:dry_run)      { false }
  let(:current_user) { maintainer }

  before do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  describe "#execute" do
    subject { service.execute }

    shared_examples "can schedule for deletion" do
      let!(:old_stopped_review_env) { create(:environment, :with_review_app, :stopped, created_at: 31.days.ago, project: project) }
      let!(:new_stopped_review_env) { create(:environment, :with_review_app, :stopped, project: project) }
      let!(:old_active_review_env)  { create(:environment, :with_review_app, :available, created_at: 31.days.ago, project: project) }
      let!(:old_stopped_other_env)  { create(:environment, :stopped, created_at: 31.days.ago, project: project) }
      let!(:new_stopped_other_env)  { create(:environment, :stopped, project: project) }
      let!(:old_active_other_env)   { create(:environment, :available, created_at: 31.days.ago, project: project) }
      let!(:already_deleting_env)   { create(:environment, :with_review_app, :stopped, created_at: 31.days.ago, project: project, auto_delete_at: 1.day.from_now) }
      let(:already_deleting_time)   { already_deleting_env.reload.auto_delete_at }

      context "live run" do
        let(:dry_run) { false }

        around do |example|
          freeze_time { example.run }
        end

        it "marks the correct environment as scheduled_entries" do
          expect(subject.success?).to be_truthy
          expect(subject.scheduled_entries).to contain_exactly(old_stopped_review_env)
          expect(subject.unprocessable_entries).to be_empty

          old_stopped_review_env.reload
          new_stopped_review_env.reload
          old_active_review_env.reload
          old_stopped_other_env.reload
          new_stopped_other_env.reload
          old_active_other_env.reload
          already_deleting_env.reload

          expect(old_stopped_review_env.auto_delete_at).to eq(1.week.from_now)
          expect(new_stopped_review_env.auto_delete_at).to be_nil
          expect(old_active_review_env.auto_delete_at).to be_nil
          expect(old_stopped_other_env.auto_delete_at).to be_nil
          expect(new_stopped_other_env.auto_delete_at).to be_nil
          expect(old_active_other_env.auto_delete_at).to be_nil
          expect(already_deleting_env.auto_delete_at).to eq(already_deleting_time)
        end
      end

      context "dry run" do
        let(:dry_run) { true }

        it "returns the same but doesn't update the record" do
          expect(subject.success?).to be_truthy
          expect(subject.scheduled_entries).to contain_exactly(old_stopped_review_env)
          expect(subject.unprocessable_entries).to be_empty

          old_stopped_review_env.reload
          new_stopped_review_env.reload
          old_active_review_env.reload
          old_stopped_other_env.reload
          new_stopped_other_env.reload
          old_active_other_env.reload
          already_deleting_env.reload

          expect(old_stopped_review_env.auto_delete_at).to be_nil
          expect(new_stopped_review_env.auto_delete_at).to be_nil
          expect(old_active_review_env.auto_delete_at).to be_nil
          expect(old_stopped_other_env.auto_delete_at).to be_nil
          expect(new_stopped_other_env.auto_delete_at).to be_nil
          expect(old_active_other_env.auto_delete_at).to be_nil
          expect(already_deleting_env.auto_delete_at).to eq(already_deleting_time)
        end
      end

      describe "execution in parallel" do
        before do
          stub_exclusive_lease_taken(service.send(:key))
        end

        it "does not execute unsafe_mark_scheduled_entries_environments" do
          expect(service).not_to receive(:unsafe_mark_scheduled_entries_environments)

          expect(subject.success?).to be_falsey
          expect(subject.status).to eq(:conflict)
        end
      end
    end

    context "as a maintainer" do
      let(:current_user) { maintainer }

      it_behaves_like "can schedule for deletion"
    end

    context "as a developer" do
      let(:current_user) { developer }

      it_behaves_like "can schedule for deletion"
    end

    context "as a reporter" do
      let(:current_user) { reporter }

      it "fails to delete environments" do
        old_stopped_review_env = create(:environment, :with_review_app, :stopped, created_at: 31.days.ago, project: project)

        expect(subject.success?).to be_falsey

        # Both of these should be empty as we fail before testing them
        expect(subject.scheduled_entries).to be_empty
        expect(subject.unprocessable_entries).to be_empty

        old_stopped_review_env.reload

        expect(old_stopped_review_env.auto_delete_at).to be_nil
      end
    end
  end
end
