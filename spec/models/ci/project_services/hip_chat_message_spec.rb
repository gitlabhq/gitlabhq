require 'spec_helper'

describe Ci::HipChatMessage do
  subject { Ci::HipChatMessage.new(build) }

  let(:commit) { FactoryGirl.create(:ci_commit_with_two_jobs) }

  let(:build) do
    commit.builds.first
  end

  context 'when all matrix builds succeed' do
    it 'returns a successful message' do
      commit.create_builds('master', false, nil)
      commit.builds.update_all(status: "success")
      commit.reload

      expect(subject.status_color).to eq 'green'
      expect(subject.notify?).to be_falsey
      expect(subject.to_s).to match(/Commit #\d+/)
      expect(subject.to_s).to match(/Successful in \d+ second\(s\)\./)
    end
  end

  context 'when at least one matrix build fails' do
    it 'returns a failure message' do
      commit.create_builds('master', false, nil)
      first_build = commit.builds.first
      second_build = commit.builds.last
      first_build.update(status: "success")
      second_build.update(status: "failed")

      expect(subject.status_color).to eq 'red'
      expect(subject.notify?).to be_truthy
      expect(subject.to_s).to match(/Commit #\d+/)
      expect(subject.to_s).to match(/Failed in \d+ second\(s\)\./)
    end
  end
end
