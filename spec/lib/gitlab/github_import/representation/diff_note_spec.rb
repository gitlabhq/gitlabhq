# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::DiffNote, feature_category: :importers do
  let(:hunk) do
    '@@ -1 +1 @@
    -Hello
    +Hello world'
  end

  let(:merge_request) do
    double(
      :merge_request,
      id: 54,
      diff_refs: double(
        :refs,
        base_sha: 'base',
        start_sha: 'start',
        head_sha: 'head'
      )
    )
  end

  let(:project) { double(:project, id: 836) }
  let(:note_id) { 1 }
  let(:in_reply_to_id) { nil }
  let(:start_line) { nil }
  let(:end_line) { 23 }
  let(:note_body) { 'Hello world' }
  let(:user_data) { { id: 4, login: 'alice' } }
  let(:side) { 'RIGHT' }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  shared_examples 'a DiffNote representation' do
    it 'returns an instance of DiffNote' do
      expect(note).to be_an_instance_of(described_class)
    end

    context 'the returned DiffNote' do
      it 'includes the number of the merge request' do
        expect(note.noteable_id).to eq(42)
      end

      it 'includes the file path of the diff' do
        expect(note.file_path).to eq('README.md')
      end

      it 'includes the commit ID' do
        expect(note.commit_id).to eq('123abc')
      end

      it 'includes the created timestamp' do
        expect(note.created_at).to eq(created_at)
      end

      it 'includes the updated timestamp' do
        expect(note.updated_at).to eq(updated_at)
      end

      it 'includes the GitHub ID' do
        expect(note.note_id).to eq(note_id)
      end

      it 'returns the noteable type' do
        expect(note.noteable_type).to eq('MergeRequest')
      end

      describe '#diff_hash' do
        it 'returns a Hash containing the diff details' do
          expect(note.diff_hash).to eq(
            diff: hunk,
            new_path: 'README.md',
            old_path: 'README.md',
            a_mode: '100644',
            b_mode: '100644',
            new_file: false
          )
        end
      end

      describe '#diff_position' do
        before do
          note.merge_request = double(
            :merge_request,
            diff_refs: double(
              :refs,
              base_sha: 'base',
              start_sha: 'start',
              head_sha: 'head'
            )
          )
        end

        context 'when the diff is an addition' do
          it 'returns a Gitlab::Diff::Position' do
            expect(note.diff_position.to_h).to eq(
              base_sha: 'base',
              head_sha: 'head',
              line_range: nil,
              new_line: 23,
              new_path: 'README.md',
              old_line: nil,
              old_path: 'README.md',
              position_type: 'text',
              start_sha: 'start',
              ignore_whitespace_change: false
            )
          end
        end

        context 'when the diff is an deletion' do
          let(:side) { 'LEFT' }

          it 'returns a Gitlab::Diff::Position' do
            expect(note.diff_position.to_h).to eq(
              base_sha: 'base',
              head_sha: 'head',
              line_range: nil,
              old_line: 23,
              new_path: 'README.md',
              new_line: nil,
              old_path: 'README.md',
              position_type: 'text',
              start_sha: 'start',
              ignore_whitespace_change: false
            )
          end
        end
      end

      describe '#github_identifiers' do
        it 'returns a hash with needed identifiers' do
          expect(note.github_identifiers).to eq(
            noteable_iid: 42,
            noteable_type: 'MergeRequest',
            note_id: 1
          )
        end
      end

      describe '#line_code' do
        it 'generates the proper line code' do
          note = described_class.new(diff_hunk: hunk, file_path: 'README.md')

          expect(note.line_code).to eq('8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_2_2')
        end

        context 'when comment on file' do
          it 'generates line code for first line' do
            note = described_class.new(diff_hunk: '', file_path: 'README.md', subject_type: 'file')

            expect(note.line_code).to eq('8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_1_1')
          end
        end
      end

      describe '#note and #contains_suggestion?' do
        it 'includes the note body' do
          expect(note.note).to eq('Hello world')
          expect(note.contains_suggestion?).to eq(false)
        end

        context 'when the note have a suggestion' do
          let(:note_body) do
            <<~BODY
            ```suggestion
            Hello World
            ```
            BODY
          end

          it 'returns the suggestion formatted in the note' do
            expect(note.note).to eq <<~BODY
            ```suggestion:-0+0
            Hello World
            ```
            BODY
            expect(note.contains_suggestion?).to eq(true)
          end
        end

        context 'when the note have a multiline suggestion' do
          let(:start_line) { 20 }
          let(:end_line) { 23 }
          let(:note_body) do
            <<~BODY
            ```suggestion
            Hello World
            ```
            BODY
          end

          it 'returns the multi-line suggestion formatted in the note' do
            expect(note.note).to eq <<~BODY
            ```suggestion:-3+0
            Hello World
            ```
            BODY
            expect(note.contains_suggestion?).to eq(true)
          end
        end

        describe '#author' do
          it 'includes the user details' do
            expect(note.author).to be_an_instance_of(
              Gitlab::GithubImport::Representation::User
            )

            expect(note.author.id).to eq(4)
            expect(note.author.login).to eq('alice')
          end

          context 'when the author is empty' do
            let(:user_data) { nil }

            it 'does not set the user if the response did not include a user' do
              expect(note.author).to be_nil
            end
          end
        end
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      {
        id: note_id,
        html_url: 'https://github.com/foo/bar/pull/42',
        path: 'README.md',
        commit_id: '123abc',
        original_commit_id: 'original123abc',
        side: side,
        user: user_data,
        diff_hunk: hunk,
        body: note_body,
        created_at: created_at,
        updated_at: updated_at,
        line: end_line,
        start_line: start_line,
        in_reply_to_id: in_reply_to_id
      }
    end

    subject(:note) { described_class.from_api_response(response) }

    it_behaves_like 'a DiffNote representation'

    describe '#discussion_id' do
      it 'finds or generates discussion_id value' do
        discussion_id = 'discussion_id'
        discussion_id_class = Gitlab::GithubImport::Representation::DiffNotes::DiscussionId

        expect_next_instance_of(discussion_id_class, response) do |discussion_id_object|
          expect(discussion_id_object).to receive(:find_or_generate).and_return(discussion_id)
        end

        expect(note.discussion_id).to eq(discussion_id)
      end
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a DiffNote representation' do
      let(:hash) do
        {
          'note_id' => note_id,
          'html_url' => 'https://github.com/foo/bar/pull/42',
          'noteable_type' => 'MergeRequest',
          'noteable_id' => 42,
          'file_path' => 'README.md',
          'commit_id' => '123abc',
          'original_commit_id' => 'original123abc',
          'side' => side,
          'author' => user_data,
          'diff_hunk' => hunk,
          'note' => note_body,
          'created_at' => created_at.to_s,
          'updated_at' => updated_at.to_s,
          'end_line' => end_line,
          'start_line' => start_line,
          'in_reply_to_id' => in_reply_to_id,
          'discussion_id' => 'FIRST_DISCUSSION_ID'
        }
      end

      subject(:note) { described_class.from_json_hash(hash) }
    end
  end
end
