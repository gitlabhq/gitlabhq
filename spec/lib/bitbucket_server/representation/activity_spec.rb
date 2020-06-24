# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::Activity do
  let(:activities) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/activities.json'))['values'] }
  let(:inline_comment) { activities.first }
  let(:comment) { activities[3] }
  let(:merge_event) { activities[4] }

  describe 'regular comment' do
    subject { described_class.new(comment) }

    it { expect(subject.comment?).to be_truthy }
    it { expect(subject.inline_comment?).to be_falsey }
    it { expect(subject.comment).to be_a(BitbucketServer::Representation::Comment) }
    it { expect(subject.created_at).to be_a(Time) }
  end

  describe 'inline comment' do
    subject { described_class.new(inline_comment) }

    it { expect(subject.comment?).to be_truthy }
    it { expect(subject.inline_comment?).to be_truthy }
    it { expect(subject.comment).to be_a(BitbucketServer::Representation::PullRequestComment) }
    it { expect(subject.created_at).to be_a(Time) }
  end

  describe 'merge event' do
    subject { described_class.new(merge_event) }

    it { expect(subject.comment?).to be_falsey }
    it { expect(subject.inline_comment?).to be_falsey }
    it { expect(subject.committer_user).to eq('root') }
    it { expect(subject.committer_email).to eq('test.user@example.com') }
    it { expect(subject.merge_timestamp).to be_a(Time) }
    it { expect(subject.created_at).to be_a(Time) }
    it { expect(subject.merge_commit).to eq('839fa9a2d434eb697815b8fcafaecc51accfdbbc') }
  end
end
