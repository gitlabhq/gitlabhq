require 'spec_helper'

describe 'CycleAnalytics#issue', models: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  subject { CycleAnalytics.new(project, from: from_date) }

  context "when a milestone is added to the issue" do
    it "calculates the median of available durations (between issue creation and milestone addition)" do
      time_differences = Array.new(5) do
        start_time = Time.now
        end_time = rand(1..10).days.from_now

        milestone = create(:milestone, project: project)
        issue = Timecop.freeze(start_time) { create(:issue, project: project) }
        Timecop.freeze(end_time) { issue.update(milestone: milestone) }

        end_time - start_time
      end

      median_time_difference = time_differences.sort[2]
      expect(subject.issue).to eq(median_time_difference)
    end
  end

  context "when a label is added to the issue" do
    context "when the label is a list-label" do
      it "calculates the median of available durations (between issue creation and label addition)" do
        time_differences = Array.new(5) do
          start_time = Time.now
          end_time = rand(1..10).days.from_now

          list_label = create(:label, lists: [create(:list)])
          issue = Timecop.freeze(start_time) { create(:issue, project: project) }
          Timecop.freeze(end_time) { issue.update(label_ids: [list_label.id]) }

          end_time - start_time
        end

        median_time_difference = time_differences.sort[2]
        expect(subject.issue).to eq(median_time_difference)
      end
    end

    it "does not make a calculation for regular labels" do
      5.times do
        regular_label = create(:label)
        issue = create(:issue, project: project)
        issue.update(label_ids: [regular_label.id])
      end

      expect(subject.issue).to be_nil
    end
  end

  context "when a milestone and list-label are both added to the issue" do
    it "calculates the median of available durations (between issue creation and milestone addition)" do
      start_time = Time.now
      milestone_add_time = rand(1..10).days.from_now
      list_label_add_time = rand(1..10).days.from_now

      milestone = create(:milestone, project: project)
      list_label = create(:label, lists: [create(:list)])
      issue = Timecop.freeze(start_time) { create(:issue, project: project) }
      Timecop.freeze(milestone_add_time) { issue.update(milestone: milestone) }
      Timecop.freeze(list_label_add_time) { issue.update(label_ids: [list_label.id]) }

      expect(subject.issue).to eq(milestone_add_time - start_time)
    end

    it "does not include issues from other projects" do
      milestone = create(:milestone, project: project)
      list_label = create(:label, lists: [create(:list)])
      issue = create(:issue)
      issue.update(milestone: milestone)
      issue.update(label_ids: [list_label.id])

      expect(subject.issue).to be_nil
    end

    it "excludes issues created before the 'from' date" do
      before_from_date = from_date - 5.days

      milestone = create(:milestone, project: project)
      list_label = create(:label, lists: [create(:list)])
      issue = Timecop.freeze(before_from_date) { create(:issue, project: project)}
      issue.update(milestone: milestone)
      issue.update(label_ids: [list_label.id])

      expect(subject.issue).to be_nil
    end
  end
end
