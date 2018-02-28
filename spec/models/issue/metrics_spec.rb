require 'spec_helper'

describe Issue::Metrics do
  let(:project) { create(:project) }

  subject { create(:issue, project: project) }

  describe "when recording the default set of issue metrics on issue save" do
    context "milestones" do
      it "records the first time an issue is associated with a milestone" do
        time = Time.now
        Timecop.freeze(time) { subject.update(milestone: create(:milestone)) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_associated_with_milestone_at).to be_like_time(time)
      end

      it "does not record the second time an issue is associated with a milestone" do
        time = Time.now
        Timecop.freeze(time) { subject.update(milestone: create(:milestone)) }
        Timecop.freeze(time + 2.hours) { subject.update(milestone: nil) }
        Timecop.freeze(time + 6.hours) { subject.update(milestone: create(:milestone)) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_associated_with_milestone_at).to be_like_time(time)
      end
    end

    context "list labels" do
      it "records the first time an issue is associated with a list label" do
        list_label = create(:label, lists: [create(:list)])
        time = Time.now
        Timecop.freeze(time) { subject.update(label_ids: [list_label.id]) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_added_to_board_at).to be_like_time(time)
      end

      it "does not record the second time an issue is associated with a list label" do
        time = Time.now
        first_list_label = create(:label, lists: [create(:list)])
        Timecop.freeze(time) { subject.update(label_ids: [first_list_label.id]) }
        second_list_label = create(:label, lists: [create(:list)])
        Timecop.freeze(time + 5.hours) { subject.update(label_ids: [second_list_label.id]) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_added_to_board_at).to be_like_time(time)
      end
    end
  end
end
