# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::Comment, feature_category: :importers do
  let(:activities) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/activities.json'))['values'] }
  let(:comment) { activities.first }

  subject(:comment_representation) { described_class.new(comment) }

  describe '#id' do
    it { expect(comment_representation.id).to eq(9) }
  end

  describe '#author_name' do
    it { expect(comment_representation.author_name).to eq('root') }
  end

  describe '#author_username' do
    it 'returns username' do
      expect(comment_representation.author_username).to eq('username')
    end

    context 'when username is absent' do
      before do
        comment['comment']['author'].delete('username')
      end

      it 'returns slug' do
        expect(comment_representation.author_username).to eq('slug')
      end
    end

    context 'when slug and username are absent' do
      before do
        comment['comment']['author'].delete('username')
        comment['comment']['author'].delete('slug')
      end

      it 'returns displayName' do
        expect(comment_representation.author_username).to eq('root')
      end
    end
  end

  describe '#author_email' do
    it { expect(comment_representation.author_email).to eq('test.user@example.com') }
  end

  describe '#note' do
    it { expect(comment_representation.note).to eq('is this a new line?') }
  end

  describe '#created_at' do
    it { expect(comment_representation.created_at).to be_a(Time) }
  end

  describe '#updated_at' do
    it { expect(comment_representation.updated_at).to be_a(Time) }
  end

  describe '#comments' do
    it { expect(comment_representation.comments.count).to eq(4) }
    it { expect(comment_representation.comments).to all(be_a(described_class)) }
    it { expect(comment_representation.comments.map(&:note)).to match_array(["Hello world", "Ok", "hello", "hi"]) }

    # The thread should look like:
    #
    # is this a new line? (comment_representation)
    #   -> Hello world (first)
    #      -> Ok (third)
    #      -> Hi (fourth)
    #   -> hello (second)
    it 'comments have the right parent' do
      first, second, third, fourth = comment_representation.comments[0..4]

      expect(comment_representation.parent_comment).to be_nil
      expect(first.parent_comment).to eq(comment_representation)
      expect(second.parent_comment).to eq(comment_representation)
      expect(third.parent_comment).to eq(first)
      expect(fourth.parent_comment).to eq(first)
    end
  end

  describe '#to_hash' do
    specify do
      expect(comment_representation.to_hash).to match(
        a_hash_including(
          id: 9,
          author_name: 'root',
          author_email: 'test.user@example.com',
          author_username: 'username',
          note: 'is this a new line?',
          comments: array_including(
            hash_including(
              note: 'Hello world',
              comments: [],
              parent_comment_note: 'is this a new line?'
            ),
            hash_including(
              note: 'Ok',
              comments: [],
              parent_comment_note: 'Hello world'
            ),
            hash_including(
              note: 'hi',
              comments: [],
              parent_comment_note: 'Hello world'
            ),
            hash_including(
              note: 'hello',
              comments: [],
              parent_comment_note: 'is this a new line?'
            )
          )
        )
      )
    end
  end
end
