require 'spec_helper'

describe CycleAnalytics::Summary, models: true do
  let(:project) { create(:project) }
  let(:from) { Time.now }
  let(:user) { create(:user, :admin) }
  subject { described_class.new(project, user, from: from) }

  describe "#new_issues" do
    it "finds the number of issues created after the 'from date'" do
      Timecop.freeze(5.days.ago) { create(:issue, project: project) }
      Timecop.freeze(5.days.from_now) { create(:issue, project: project) }

      expect(subject.new_issues).to eq(1)
    end

    it "doesn't find issues from other projects" do
      Timecop.freeze(5.days.from_now) { create(:issue, project: create(:project)) }

      expect(subject.new_issues).to eq(0)
    end
  end

  describe "#commits" do
    it "finds the number of commits created after the 'from date'" do
      Timecop.freeze(5.days.ago) { create_commit("Test message", project, user, 'master') }
      Timecop.freeze(5.days.from_now) { create_commit("Test message", project, user, 'master') }

      expect(subject.commits).to eq(1)
    end

    it "doesn't find commits from other projects" do
      Timecop.freeze(5.days.from_now) { create_commit("Test message", create(:project), user, 'master') }

      expect(subject.commits).to eq(0)
    end

    it "finds a large (> 100) snumber of commits if present" do
      Timecop.freeze(5.days.from_now) { create_commit("Test message", project, user, 'master', count: 100) }

      expect(subject.commits).to eq(100)
    end
  end

  describe "#deploys" do
    it "finds the number of deploys made created after the 'from date'" do
      Timecop.freeze(5.days.ago) { create(:deployment, project: project) }
      Timecop.freeze(5.days.from_now) { create(:deployment, project: project) }

      expect(subject.deploys).to eq(1)
    end

    it "doesn't find commits from other projects" do
      Timecop.freeze(5.days.from_now) { create(:deployment, project: create(:project)) }

      expect(subject.deploys).to eq(0)
    end
  end
end
