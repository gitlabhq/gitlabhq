# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CycleAnalytics::StageSummary do
  let(:project) { create(:project, :repository) }
  let(:from) { 1.day.ago }
  let(:user) { create(:user, :admin) }
  subject { described_class.new(project, from: Time.now, current_user: user).data }

  before do
    project.add_maintainer(user)
  end

  describe "#new_issues" do
    it "finds the number of issues created after the 'from date'" do
      Timecop.freeze(5.days.ago) { create(:issue, project: project) }
      Timecop.freeze(5.days.from_now) { create(:issue, project: project) }

      expect(subject.first[:value]).to eq(1)
    end

    it "doesn't find issues from other projects" do
      Timecop.freeze(5.days.from_now) { create(:issue, project: create(:project)) }

      expect(subject.first[:value]).to eq(0)
    end
  end

  describe "#commits" do
    it "finds the number of commits created after the 'from date'" do
      Timecop.freeze(5.days.ago) { create_commit("Test message", project, user, 'master') }
      Timecop.freeze(5.days.from_now) { create_commit("Test message", project, user, 'master') }

      expect(subject.second[:value]).to eq(1)
    end

    it "doesn't find commits from other projects" do
      Timecop.freeze(5.days.from_now) { create_commit("Test message", create(:project, :repository), user, 'master') }

      expect(subject.second[:value]).to eq(0)
    end

    it "finds a large (> 100) snumber of commits if present" do
      Timecop.freeze(5.days.from_now) { create_commit("Test message", project, user, 'master', count: 100) }

      expect(subject.second[:value]).to eq(100)
    end

    context 'when a guest user is signed in' do
      let(:guest_user) { create(:user) }

      before do
        project.add_guest(guest_user)
      end

      it 'does not include commit stats' do
        data = described_class.new(project, from: from, current_user: guest_user).data
        expect(includes_commits?(data)).to be_falsy
      end

      def includes_commits?(data)
        data.any? { |h| h["title"] == 'Commits' }
      end
    end
  end

  describe "#deploys" do
    it "finds the number of deploys made created after the 'from date'" do
      Timecop.freeze(5.days.ago) { create(:deployment, :success, project: project) }
      Timecop.freeze(5.days.from_now) { create(:deployment, :success, project: project) }

      expect(subject.third[:value]).to eq(1)
    end

    it "doesn't find commits from other projects" do
      Timecop.freeze(5.days.from_now) do
        create(:deployment, :success, project: create(:project, :repository))
      end

      expect(subject.third[:value]).to eq(0)
    end
  end
end
