# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::Summary::Commit, feature_category: :devops_reports do
  let_it_be(:project) { create(:project, :repository) }

  let(:from) { 1.week.ago }
  let(:to) { Time.current }
  let(:options) { { from: from, to: to } }

  subject(:summary_commit) { described_class.new(project: project, options: options) }

  it 'returns correct identifier and title' do
    allow(project.repository).to receive(:count_commits).and_return(5)

    expect(summary_commit.identifier).to eq(:commits)
    expect(summary_commit.title).to eq('Commits')
  end

  describe '#value' do
    it 'returns PrettyNumeric value and calls repository.count_commits with correct parameters' do
      expect(project.repository).to receive(:count_commits).with(
        ref: project.default_branch,
        after: from,
        before: to
      ).and_return(10)

      value = summary_commit.value

      expect(value).to be_a(Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric)
      expect(value.to_s).to eq('10')
    end

    it 'returns None value when default branch is blank' do
      allow(project).to receive(:default_branch).and_return(nil)

      expect(project.repository).not_to receive(:count_commits)
      expect(summary_commit.value).to be_a(Gitlab::CycleAnalytics::Summary::Value::None)
      expect(summary_commit.value.to_s).to eq('-')
    end

    it 'returns None value when count_commits returns nil' do
      allow(project.repository).to receive(:count_commits).and_return(nil)

      expect(summary_commit.value).to be_a(Gitlab::CycleAnalytics::Summary::Value::None)
    end
  end
end
