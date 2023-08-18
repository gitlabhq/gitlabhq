# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussion, feature_category: :team_planning do
  subject { described_class.new([first_note, second_note, third_note]) }

  let_it_be(:first_note) { create(:diff_note_on_merge_request) }
  let_it_be(:merge_request) { first_note.noteable }
  let_it_be(:second_note) { create(:diff_note_on_merge_request, in_reply_to: first_note) }
  let_it_be(:third_note) { create(:diff_note_on_merge_request) }

  describe '.lazy_find' do
    let!(:note1) { create(:discussion_note_on_merge_request).to_discussion }
    let!(:note2) { create(:discussion_note_on_merge_request, in_reply_to: note1).to_discussion }

    subject { [note1, note2].map { |note| described_class.lazy_find(note.discussion_id) } }

    it 'batches requests' do
      expect do
        [described_class.lazy_find(note1.id),
         described_class.lazy_find(note2.id)].map(&:__sync)
      end.not_to exceed_query_limit(1)
    end
  end

  describe '.build' do
    it 'returns a discussion of the right type' do
      discussion = described_class.build([first_note, second_note], merge_request)
      expect(discussion).to be_a(DiffDiscussion)
      expect(discussion.notes.count).to be(2)
      expect(discussion.first_note).to be(first_note)
      expect(discussion.noteable).to be(merge_request)
    end
  end

  describe '.build_collection' do
    it 'returns an array of discussions of the right type' do
      discussions = described_class.build_collection([first_note, second_note, third_note], merge_request)
      expect(discussions).to eq(
        [
          DiffDiscussion.new([first_note, second_note], merge_request),
          DiffDiscussion.new([third_note], merge_request)
        ])
    end
  end

  describe 'authorization' do
    it 'delegates to the first note' do
      policy = DeclarativePolicy.policy_for(instance_double(User, id: 1), subject)

      expect(policy).to be_a(NotePolicy)
    end
  end

  describe '#cache_key' do
    let(:notes_sha) { Digest::SHA1.hexdigest("#{subject.notes[0].post_processed_cache_key}:#{subject.notes[1].post_processed_cache_key}:#{subject.notes[2].post_processed_cache_key}") }

    it 'returns the cache key' do
      expect(subject.cache_key).to eq("#{described_class::CACHE_VERSION}:#{subject.id}:#{notes_sha}:")
    end

    context 'when discussion is resolved' do
      before do
        subject.resolve!(first_note.author)
      end

      it 'returns the cache key with resolved at' do
        expect(subject.cache_key).to eq("#{described_class::CACHE_VERSION}:#{subject.id}:#{notes_sha}:#{subject.resolved_at}")
      end
    end
  end

  describe '#to_global_id' do
    context 'with a single DiffNote discussion' do
      it 'returns GID on Discussion class' do
        discussion = described_class.build([first_note], merge_request)
        discussion_id = discussion.id

        expect(discussion.class.name.to_s).to eq("DiffDiscussion")
        expect(discussion.to_global_id.to_s).to eq("gid://gitlab/Discussion/#{discussion_id}")
      end
    end

    context 'with multiple DiffNotes discussion' do
      it 'returns GID on Discussion class' do
        discussion = described_class.build([first_note, second_note], merge_request)
        discussion_id = discussion.id

        expect(discussion.class.name.to_s).to eq("DiffDiscussion")
        expect(discussion.to_global_id.to_s).to eq("gid://gitlab/Discussion/#{discussion_id}")
      end
    end

    context 'with discussions on issue' do
      let_it_be(:note_1, refind: true) { create(:note) }
      let_it_be(:noteable) { note_1.noteable }

      context 'with a single Note' do
        it 'returns GID on Discussion class' do
          discussion = described_class.build([note_1], noteable)
          discussion_id = discussion.id

          expect(discussion.class.name.to_s).to eq("IndividualNoteDiscussion")
          expect(discussion.to_global_id.to_s).to eq("gid://gitlab/Discussion/#{discussion_id}")
        end
      end

      context 'with multiple Notes' do
        let_it_be(:note_1, refind: true) { create(:note, type: 'DiscussionNote') }
        let_it_be(:note_2, refind: true) { create(:note, in_reply_to: note_1) }

        it 'returns GID on Discussion class' do
          discussion = described_class.build([note_1, note_2], noteable)
          discussion_id = discussion.id

          expect(discussion.class.name.to_s).to eq("Discussion")
          expect(discussion.to_global_id.to_s).to eq("gid://gitlab/Discussion/#{discussion_id}")
        end
      end
    end

    context 'with system notes' do
      let_it_be(:system_note, refind: true) { create(:note, system: true) }
      let_it_be(:noteable) { system_note.noteable }

      it 'returns GID on Discussion class' do
        discussion = described_class.build([system_note], noteable)
        discussion_id = discussion.id

        expect(discussion.class.name.to_s).to eq("IndividualNoteDiscussion")
        expect(discussion.to_global_id.to_s).to eq("gid://gitlab/Discussion/#{discussion_id}")
      end
    end
  end
end
