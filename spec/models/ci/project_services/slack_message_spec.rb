require 'spec_helper'

describe Ci::SlackMessage do
  subject { Ci::SlackMessage.new(commit) }

  let(:commit) { FactoryGirl.create(:ci_commit_with_two_jobs) }

  context 'when all matrix builds succeeded' do
    let(:color) { 'good' }

    it 'returns a message with success' do
      commit.create_builds('master', false, nil)
      commit.builds.update_all(status: "success")
      commit.reload

      expect(subject.color).to eq(color)
      expect(subject.fallback).to include('Commit')
      expect(subject.fallback).to include("\##{commit.id}")
      expect(subject.fallback).to include('succeeded')
      expect(subject.attachments.first[:fields]).to be_empty
    end
  end

  context 'when one of matrix builds failed' do
    let(:color) { 'danger' }

    it 'returns a message with information about failed build' do
      commit.create_builds('master', false, nil)
      first_build = commit.builds.first
      second_build = commit.builds.last
      first_build.update(status: "success")
      second_build.update(status: "failed")

      expect(subject.color).to eq(color)
      expect(subject.fallback).to include('Commit')
      expect(subject.fallback).to include("\##{commit.id}")
      expect(subject.fallback).to include('failed')
      expect(subject.attachments.first[:fields].size).to eq(1)
      expect(subject.attachments.first[:fields].first[:title]).to eq(second_build.name)
      expect(subject.attachments.first[:fields].first[:value]).to include("\##{second_build.id}")
    end
  end
end
