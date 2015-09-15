require 'spec_helper'

describe Ci::SlackMessage do
  subject { Ci::SlackMessage.new(commit) }

  let(:project) { FactoryGirl.create :ci_project }

  context "One build" do
    let(:commit) { FactoryGirl.create(:ci_commit_with_one_job, project: project) }

    let(:build) do
      commit.create_builds
      commit.builds.first
    end

    context 'when build succeeded' do
      let(:color) { 'good' }

      it 'returns a message with succeeded build' do
        build.update(status: "success")

        expect(subject.color).to eq(color)
        expect(subject.fallback).to include('Build')
        expect(subject.fallback).to include("\##{build.id}")
        expect(subject.fallback).to include('succeeded')
        expect(subject.attachments.first[:fields]).to be_empty
      end
    end

    context 'when build failed' do
      let(:color) { 'danger' }

      it 'returns a message with failed build' do
        build.update(status: "failed")

        expect(subject.color).to eq(color)
        expect(subject.fallback).to include('Build')
        expect(subject.fallback).to include("\##{build.id}")
        expect(subject.fallback).to include('failed')
        expect(subject.attachments.first[:fields]).to be_empty
      end
    end
  end

  context "Several builds" do
    let(:commit) { FactoryGirl.create(:ci_commit_with_two_jobs, project: project) }

    context 'when all matrix builds succeeded' do
      let(:color) { 'good' }

      it 'returns a message with success' do
        commit.create_builds
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
        commit.create_builds
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
end
