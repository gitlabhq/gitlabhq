# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::Comment do
  let(:activities) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/activities.json'))['values'] }
  let(:comment) { activities.first }

  subject { described_class.new(comment) }

  describe '#id' do
    it { expect(subject.id).to eq(9) }
  end

  describe '#author_username' do
    it 'returns username' do
      expect(subject.author_username).to eq('username')
    end

    context 'when username is absent' do
      before do
        comment['comment']['author'].delete('username')
      end

      it 'returns slug' do
        expect(subject.author_username).to eq('slug')
      end
    end

    context 'when slug and username are absent' do
      before do
        comment['comment']['author'].delete('username')
        comment['comment']['author'].delete('slug')
      end

      it 'returns displayName' do
        expect(subject.author_username).to eq('root')
      end
    end
  end

  describe '#author_email' do
    it { expect(subject.author_email).to eq('test.user@example.com' ) }
  end

  describe '#note' do
    it { expect(subject.note).to eq('is this a new line?') }
  end

  describe '#created_at' do
    it { expect(subject.created_at).to be_a(Time) }
  end

  describe '#updated_at' do
    it { expect(subject.created_at).to be_a(Time) }
  end

  describe '#comments' do
    it { expect(subject.comments.count).to eq(4) }
    it { expect(subject.comments).to all( be_a(described_class) ) }
    it { expect(subject.comments.map(&:note)).to match_array(["Hello world", "Ok", "hello", "hi"]) }

    # The thread should look like:
    #
    # is this a new line? (subject)
    #   -> Hello world (first)
    #      -> Ok (third)
    #      -> Hi (fourth)
    #   -> hello (second)
    it 'comments have the right parent' do
      first, second, third, fourth = subject.comments[0..4]

      expect(subject.parent_comment).to be_nil
      expect(first.parent_comment).to eq(subject)
      expect(second.parent_comment).to eq(subject)
      expect(third.parent_comment).to eq(first)
      expect(fourth.parent_comment).to eq(first)
    end
  end
end
