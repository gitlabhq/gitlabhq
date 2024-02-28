# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::StageSummary, feature_category: :devops_reports do
  include CycleAnalyticsHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:options) { { from: 1.day.ago } }
  let(:args) { { options: options, current_user: user } }
  let(:user) { create(:user, :admin) }

  before do
    project.add_maintainer(user)
  end

  let(:stage_summary) { described_class.new(project, **args).data }

  describe '#identifier' do
    it 'returns identifiers for each metric' do
      identifiers = stage_summary.pluck(:identifier)
      expect(identifiers).to eq(%i[issues commits deploys deployment_frequency])
    end
  end

  describe "#new_issues" do
    subject { stage_summary.first }

    context 'when from date is given' do
      before do
        travel_to(5.days.ago) { create(:issue, project: project) }
        travel_to(5.days.from_now) { create(:issue, project: project) }
      end

      it "finds the number of issues created after the 'from date'" do
        expect(subject[:value]).to eq('1')
      end

      it 'returns the localized title' do
        Gitlab::I18n.with_locale(:ru) do
          expect(subject[:title]).to eq(n_('New issue', 'New issues', 1))
        end
      end
    end

    it "doesn't find issues from other projects" do
      travel_to(5.days.from_now) { create(:issue, project: create(:project)) }

      expect(subject[:value]).to eq('-')
    end

    context 'when `to` parameter is given' do
      before do
        travel_to(5.days.ago) { create(:issue, project: project) }
        travel_to(5.days.from_now) { create(:issue, project: project) }
      end

      it "doesn't find any record" do
        options[:to] = Time.now

        expect(subject[:value]).to eq('-')
      end

      it "finds records created between `from` and `to` range" do
        options[:from] = 10.days.ago
        options[:to] = 10.days.from_now

        expect(subject[:value]).to eq('2')
      end
    end
  end

  describe "#commits" do
    let!(:project) { create(:project, :repository) }

    subject { stage_summary.second }

    context 'when from date is given' do
      before do
        travel_to(5.days.ago) { create_commit("Test message", project, user, 'master') }
        travel_to(5.days.from_now) { create_commit("Test message", project, user, 'master') }
      end

      it "finds the number of commits created after the 'from date'" do
        expect(subject[:value]).to eq('1')
      end

      it 'returns the localized title' do
        Gitlab::I18n.with_locale(:ru) do
          expect(subject[:title]).to eq(n_('Commit', 'Commits', 1))
        end
      end
    end

    it "doesn't find commits from other projects" do
      travel_to(5.days.from_now) { create_commit("Test message", create(:project, :repository), user, 'master') }

      expect(subject[:value]).to eq('-')
    end

    it "finds a large (> 100) number of commits if present" do
      travel_to(5.days.from_now) { create_commit("Test message", project, user, 'master', count: 100) }

      expect(subject[:value]).to eq('100')
    end

    context 'when `to` parameter is given' do
      before do
        travel_to(5.days.ago) { create_commit("Test message", project, user, 'master') }
        travel_to(5.days.from_now) { create_commit("Test message", project, user, 'master') }
      end

      it "doesn't find any record" do
        options[:to] = Time.now

        expect(subject[:value]).to eq('-')
      end

      it "finds records created between `from` and `to` range" do
        options[:from] = 10.days.ago
        options[:to] = 10.days.from_now

        expect(subject[:value]).to eq('2')
      end
    end

    context 'when a guest user is signed in' do
      let(:guest_user) { create(:user) }

      before do
        project.add_guest(guest_user)
        args.merge!({ current_user: guest_user })
      end

      it 'does not include commit stats' do
        data = described_class.new(project, **args).data
        expect(includes_commits?(data)).to be_falsy
      end

      def includes_commits?(data)
        data.any? { |h| h["title"] == 'Commits' }
      end
    end
  end

  it_behaves_like 'deployment metrics examples'
end
