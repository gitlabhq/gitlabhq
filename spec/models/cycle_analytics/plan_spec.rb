require 'spec_helper'

describe 'CycleAnalytics#plan', feature: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  def create_commit_referencing_issue(issue, time: Time.now)
    sha = Timecop.freeze(time) { project.repository.commit_file(user, FFaker::Product.brand, "content", "Commit for ##{issue.iid}", "master", false) }
    commit = project.repository.commit(sha)
    commit.create_cross_references!
  end

  context "when a milestone is added to the issue" do
    context "when the issue is mentioned in a commit" do
      it "calculates the median of available durations between the two" do
        time_differences = Array.new(5) do
          start_time = Time.now
          end_time = rand(1..10).days.from_now

          milestone = create(:milestone, project: project)
          issue = create(:issue, project: project)

          Timecop.freeze(start_time) { issue.update(milestone: milestone) }
          create_commit_referencing_issue(issue, time: end_time)

          end_time - start_time
        end

        median_time_difference = time_differences.sort[2]

        # Use `be_within` to account for time lost between Rails invoking CLI git
        # and the commit being created, which Timecop can't freeze.
        expect(subject.plan).to be_within(2).of(median_time_difference)
      end
    end
  end

  context "when a label is added to the issue" do
    context "when the issue is mentioned in a commit" do
      context "when the label is a list-label" do
        it "calculates the median of available durations between the two" do
          time_differences = Array.new(5) do
            start_time = Time.now
            end_time = rand(1..10).days.from_now

            issue = create(:issue, project: project)
            list_label = create(:label, lists: [create(:list)])

            Timecop.freeze(start_time) { issue.update(label_ids: [list_label.id]) }
            create_commit_referencing_issue(issue, time: end_time)

            end_time - start_time
          end

          median_time_difference = time_differences.sort[2]

          # Use `be_within` to account for time lost between Rails invoking CLI git
          # and the commit being created, which Timecop can't freeze.
          expect(subject.plan).to be_within(2).of(median_time_difference)
        end
      end

      it "does not make a calculation for regular labels" do
        5.times do
          regular_label = create(:label)
          issue = create(:issue, project: project)
          issue.update(label_ids: [regular_label.id])

          create_commit_referencing_issue(issue)
        end

        expect(subject.plan).to be_nil
      end
    end
  end

  context "when a milestone and list-label are both added to the issue" do
    context "when the issue is mentioned in a commit" do
      it "calculates the median of available durations between the two (using milestone addition as the 'start_time')" do
        time_differences = Array.new(5) do
          label_addition_time = Time.now
          milestone_addition_time = rand(2..12).hours.from_now
          end_time = rand(1..10).days.from_now

          issue = create(:issue, project: project)
          milestone = create(:milestone, project: project)
          list_label = create(:label, lists: [create(:list)])

          Timecop.freeze(label_addition_time) { issue.update(label_ids: [list_label.id]) }
          Timecop.freeze(milestone_addition_time) { issue.update(milestone: milestone) }
          create_commit_referencing_issue(issue, time: end_time)

          end_time - milestone_addition_time
        end

        median_time_difference = time_differences.sort[2]

        # Use `be_within` to account for time lost between Rails invoking CLI git
        # and the commit being created, which Timecop can't freeze.
        expect(subject.plan).to be_within(2).of(median_time_difference)
      end

      it "does not include issues from other projects" do
        other_project = create(:project)

        list_label = create(:label, lists: [create(:list)])
        issue = create(:issue, project: other_project)
        issue.update(milestone: create(:milestone))
        issue.update(label_ids: [list_label.id])
        create_commit_referencing_issue(issue)

        expect(subject.issue).to be_nil
      end

      it "excludes issues created before the 'from' date" do
        before_from_date = from_date - 5.days

        milestone = create(:milestone, project: project)
        list_label = create(:label, lists: [create(:list)])
        issue = Timecop.freeze(before_from_date) { create(:issue, project: project)}
        issue.update(milestone: milestone)
        issue.update(label_ids: [list_label.id])
        create_commit_referencing_issue(issue)

        expect(subject.issue).to be_nil
      end
    end
  end
end
