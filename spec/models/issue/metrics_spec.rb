# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue::Metrics do
  let(:project) { create(:project) }

  subject { create(:issue, project: project) }

  describe '.for_issues' do
    subject(:scope) { described_class.for_issues([issue1, issue2]) }

    let(:issue1) { create(:issue) }
    let(:issue2) { create(:issue) }

    it 'returns metrics associated with given issues' do
      create(:issue)

      expect(scope).to match_array([issue1.metrics, issue2.metrics])
    end
  end

  describe '.with_first_mention_not_earlier_than' do
    subject(:scope) { described_class.with_first_mention_not_earlier_than(timestamp) }

    let(:timestamp) { DateTime.current }

    it 'returns metrics without mentioning in commit or with mentioning after given timestamp' do
      issue1 = create(:issue)
      issue2 = create(:issue).tap { |i| i.metrics.update!(first_mentioned_in_commit_at: timestamp + 1.day) }
      create(:issue).tap { |i| i.metrics.update!(first_mentioned_in_commit_at: timestamp - 1.day) }

      expect(scope).to match_array([issue1.metrics, issue2.metrics])
    end
  end

  context "when recording the default set of issue metrics on issue save" do
    context "milestones" do
      it "records the first time an issue is associated with a milestone" do
        time = Time.current
        travel_to(time) { subject.update!(milestone: create(:milestone, project: project)) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_associated_with_milestone_at).to be_like_time(time)
      end

      it "does not record the second time an issue is associated with a milestone" do
        time = Time.current
        travel_to(time) { subject.update!(milestone: create(:milestone, project: project)) }
        travel_to(time + 2.hours) { subject.update!(milestone: nil) }
        travel_to(time + 6.hours) { subject.update!(milestone: create(:milestone, project: project)) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_associated_with_milestone_at).to be_like_time(time)
      end
    end

    context "list labels" do
      it "records the first time an issue is associated with a list label" do
        list_label = create(:list).label
        time = Time.current
        travel_to(time) { subject.update!(label_ids: [list_label.id]) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_added_to_board_at).to be_like_time(time)
      end

      it "does not record the second time an issue is associated with a list label" do
        time = Time.current
        first_list_label = create(:list).label
        travel_to(time) { subject.update!(label_ids: [first_list_label.id]) }
        second_list_label = create(:list).label
        travel_to(time + 5.hours) { subject.update!(label_ids: [second_list_label.id]) }
        metrics = subject.metrics

        expect(metrics).to be_present
        expect(metrics.first_added_to_board_at).to be_like_time(time)
      end
    end
  end
end
