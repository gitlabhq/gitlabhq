# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeboxesHelper do
  describe "#timebox_date_range" do
    let(:yesterday) { Date.yesterday }
    let(:tomorrow) { yesterday + 2 }
    let(:format) { '%b %-d, %Y' }
    let(:yesterday_formatted) { yesterday.strftime(format) }
    let(:tomorrow_formatted) { tomorrow.strftime(format) }

    context 'milestone' do
      def result_for(*args)
        timebox_date_range(build(:milestone, *args))
      end

      it { expect(result_for(due_date: nil, start_date: nil)).to be_nil }
      it { expect(result_for(due_date: tomorrow)).to eq("expires on #{tomorrow_formatted}") }
      it { expect(result_for(due_date: yesterday)).to eq("expired on #{yesterday_formatted}") }
      it { expect(result_for(start_date: tomorrow)).to eq("starts on #{tomorrow_formatted}") }
      it { expect(result_for(start_date: yesterday)).to eq("started on #{yesterday_formatted}") }
      it { expect(result_for(start_date: yesterday, due_date: tomorrow)).to eq("#{yesterday_formatted}–#{tomorrow_formatted}") }
    end
  end

  describe '#milestone_counts' do
    let(:project) { create(:project) }
    let(:counts) { helper.milestone_counts(project.milestones) }

    context 'when there are milestones' do
      it 'returns the correct counts' do
        create_list(:active_milestone, 2, project: project)
        create(:closed_milestone, project: project)

        expect(counts).to eq(opened: 2, closed: 1, all: 3)
      end
    end

    context 'when there are only milestones of one type' do
      it 'returns the correct counts' do
        create_list(:active_milestone, 2, project: project)

        expect(counts).to eq(opened: 2, closed: 0, all: 2)
      end
    end

    context 'when there are no milestones' do
      it 'returns the correct counts' do
        expect(counts).to eq(opened: 0, closed: 0, all: 0)
      end
    end
  end

  describe "#group_milestone_route" do
    let(:group) { build_stubbed(:group) }
    let(:subgroup) { build_stubbed(:group, parent: group, name: "Test Subgrp") }

    context "when in subgroup" do
      let(:milestone) { build_stubbed(:group_milestone, group: subgroup) }

      it 'generates correct url despite assigned @group' do
        assign(:group, group)
        milestone_path = "/groups/#{subgroup.full_path}/-/milestones/#{milestone.iid}"
        expect(helper.group_milestone_route(milestone)).to eq(milestone_path)
      end
    end
  end
end
