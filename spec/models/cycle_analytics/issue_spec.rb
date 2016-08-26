require 'spec_helper'

describe 'CycleAnalytics#issue', models: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  subject { CycleAnalytics.new(project, from: from_date) }

  context "when calculating the median of times between:
               start: issue created_at
                 end: milestone first added to issue
                      OR
                      list-label first added to issue
           " do
    context "when a milestone is added to the issue" do
      it "calculates the median of available durations" do
        start_and_end_times = Array.new(5) do
          start_time = Time.now
          end_time = rand(1..10).days.from_now

          milestone = create(:milestone, project: project)
          issue = Timecop.freeze(start_time) { create(:issue, project: project) }
          Timecop.freeze(end_time) { issue.update(milestone: milestone) }

          [start_time, end_time]
        end

        median_start_time, median_end_time = start_and_end_times[2]
        expect(subject.issue).to eq(median_end_time - median_start_time)
      end
    end

    context "when a label is added to the issue" do
      it "calculates the median of available durations when the label is a list-label" do
        start_and_end_times = Array.new(5) do
          start_time = Time.now
          end_time = rand(1..10).days.from_now

          list_label = create(:label, lists: [create(:list)])
          issue = Timecop.freeze(start_time) { create(:issue, project: project) }
          Timecop.freeze(end_time) { issue.update(label_ids: [list_label.id]) }

          [start_time, end_time]
        end

        median_start_time, median_end_time = start_and_end_times[2]
        expect(subject.issue).to eq(median_end_time - median_start_time)
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
      it "uses the time the milestone was added as the 'end time'" do
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
end
