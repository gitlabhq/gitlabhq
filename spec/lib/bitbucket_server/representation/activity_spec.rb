# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::Activity, feature_category: :importers do
  let(:activities) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/activities.json'))['values'] }
  let(:inline_comment) { activities.first }
  let(:comment) { activities[3] }
  let(:merge_event) { activities[4] }
  let(:approved_event) { activities[8] }
  let(:declined_event) { activities[9] }

  describe 'regular comment' do
    subject { described_class.new(comment) }

    it { expect(subject.id).to eq(11) }
    it { expect(subject.comment?).to be_truthy }
    it { expect(subject.inline_comment?).to be_falsey }
    it { expect(subject.comment).to be_a(BitbucketServer::Representation::Comment) }
    it { expect(subject.created_at).to be_a(Time) }

    describe '#to_hash' do
      it do
        expect(subject.to_hash).to match(a_hash_including(id: 11))
      end
    end
  end

  describe 'inline comment' do
    subject { described_class.new(inline_comment) }

    it { expect(subject.id).to eq(19) }
    it { expect(subject.comment?).to be_truthy }
    it { expect(subject.inline_comment?).to be_truthy }
    it { expect(subject.comment).to be_a(BitbucketServer::Representation::PullRequestComment) }
    it { expect(subject.created_at).to be_a(Time) }

    describe '#to_hash' do
      it do
        expect(subject.to_hash).to match(a_hash_including(id: 19))
      end
    end
  end

  describe 'merge event' do
    subject { described_class.new(merge_event) }

    it { expect(subject.id).to eq(7) }
    it { expect(subject.comment?).to be_falsey }
    it { expect(subject.inline_comment?).to be_falsey }
    it { expect(subject.committer_user).to eq('root') }
    it { expect(subject.committer_name).to eq('root') }
    it { expect(subject.committer_username).to eq('slug') }
    it { expect(subject.committer_email).to eq('test.user@example.com') }
    it { expect(subject.merge_timestamp).to be_a(Time) }
    it { expect(subject.created_at).to be_a(Time) }
    it { expect(subject.merge_commit).to eq('839fa9a2d434eb697815b8fcafaecc51accfdbbc') }

    describe '#to_hash' do
      it do
        expect(subject.to_hash).to match(
          a_hash_including(
            id: 7,
            committer_user: 'root',
            committer_name: 'root',
            committer_username: 'slug',
            committer_email: 'test.user@example.com',
            merge_commit: '839fa9a2d434eb697815b8fcafaecc51accfdbbc'
          )
        )
      end
    end
  end

  describe 'approved event' do
    subject { described_class.new(approved_event) }

    it { expect(subject.id).to eq(15) }
    it { expect(subject.comment?).to be_falsey }
    it { expect(subject.inline_comment?).to be_falsey }
    it { expect(subject.merge_event?).to be_falsey }
    it { expect(subject.approved_event?).to be_truthy }
    it { expect(subject.approver_name).to eq('root') }
    it { expect(subject.approver_username).to eq('slug') }
    it { expect(subject.approver_email).to eq('test.user@example.com') }
    it { expect(subject.created_at).to be_a(Time) }

    describe '#to_hash' do
      it do
        expect(subject.to_hash).to match(
          a_hash_including(
            id: 15,
            approver_name: 'root',
            approver_username: 'slug',
            approver_email: 'test.user@example.com'
          )
        )
      end
    end
  end

  describe 'declined event' do
    subject { described_class.new(declined_event) }

    it { expect(subject.id).to eq(18) }
    it { expect(subject.comment?).to be_falsey }
    it { expect(subject.inline_comment?).to be_falsey }
    it { expect(subject.merge_event?).to be_falsey }
    it { expect(subject.declined_event?).to be_truthy }
    it { expect(subject.decliner_name).to eq('root') }
    it { expect(subject.decliner_username).to eq('slug') }
    it { expect(subject.decliner_email).to eq('test.user@example.com') }
    it { expect(subject.created_at).to be_a(Time) }

    describe '#to_hash' do
      it do
        expect(subject.to_hash).to match(
          a_hash_including(
            id: 18,
            decliner_name: 'root',
            decliner_username: 'slug',
            decliner_email: 'test.user@example.com'
          )
        )
      end
    end
  end
end
