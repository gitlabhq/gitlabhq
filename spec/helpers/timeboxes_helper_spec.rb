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

  describe "#recent_releases_with_counts" do
    let_it_be(:milestone) { create(:milestone) }
    let_it_be(:project) { milestone.project }
    let_it_be(:user) { create(:user) }

    subject { helper.recent_releases_with_counts(milestone, user) }

    before do
      project.add_developer(user)
    end

    it "returns releases with counts" do
      _old_releases = create_list(:release, 2, project: project, milestones: [milestone])
      recent_public_releases = create_list(:release, 3, project: project, milestones: [milestone], released_at: '2022-01-01T18:00:00Z')

      is_expected.to match([match_array(recent_public_releases), 5, 2])
    end
  end
end
