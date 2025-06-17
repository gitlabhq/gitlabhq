# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ImportRecordPreparer, feature_category: :importers do
  describe '.recover_invalid_record' do
    subject(:recover_invalid_record) do
      # the preparer expects a validated record with errors
      record.validate

      described_class.recover_invalid_record(record)
    end

    let(:returned_record) { recover_invalid_record }

    context 'when record is a DiffNote' do
      let_it_be(:merge_request) { create(:merge_request) }
      let_it_be(:project) { create(:project) }
      let_it_be(:author) { create(:user) }
      let_it_be(:discussion_id) { 'some-discussion-id' }
      let_it_be(:resolved_at) { Time.zone.now }

      let(:record) do
        build(
          :diff_note_on_merge_request, noteable: merge_request, importing: true, note: 'About this line...',
          position: position, discussion_id: discussion_id, author_id: author.id, project_id: project.id,
          resolved_at: resolved_at, commit_id: 'some-short-id', original_position: position,
          line_code: "8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_4_7"
        )
      end

      let_it_be(:position) do
        Gitlab::Diff::Position.new(
          base_sha: "ae73cb07c9eeaf35924a10f713b364d32b2dd34f",
          head_sha: "b83d6e391c22777fca1ed3012fce84f633d7fed0",
          ignore_whitespace_change: false,
          line_range: nil,
          new_line: 9,
          new_path: 'lib/ruby/popen.rb',
          old_line: 8,
          old_path: "files/ruby/popen.rb",
          position_type: "text",
          start_sha: "0b4bc9a49b562e85de7cc9e834518ea6828729b9"
        )
      end

      context 'when diff file is not found' do
        before do
          allow(record).to receive(:fetch_diff_file).and_return(nil)
        end

        it 'builds a new DiscussionNote based on the provided DiffNote', :aggregate_failures do
          recover_invalid_record

          # Ensure the context is correct
          expect(record.errors[:base]).to include(DiffNote::DIFF_FILE_NOT_FOUND_MESSAGE)
          expect(record.errors[:base]).not_to include(/Failed to find diff line for.*/)

          expect(returned_record).to be_a(DiscussionNote)
          expect(returned_record.noteable_id).to eq(merge_request.id)
          expect(returned_record.discussion_id).to eq(discussion_id)
          expect(returned_record.author_id).to eq(author.id)
          expect(returned_record.project_id).to eq(project.id)
          expect(returned_record.resolved_at).to be(resolved_at)

          expect(returned_record.importing).to be(true)

          expect(returned_record.commit_id).to be_nil
          expect(returned_record.line_code).to be_nil
          expect(returned_record.position).to be_nil
          expect(returned_record.original_position).to be_nil
        end

        it 'adds fallback position text before the comment' do
          expect(returned_record.note).to eq(<<~COMMENT.strip)
            *Comment on files/ruby/popen.rb:8 --> lib/ruby/popen.rb:9*

            About this line...
          COMMENT
        end

        context 'when the old path and position do not exist' do
          let_it_be(:position) do
            Gitlab::Diff::Position.new(
              old_path: nil,
              new_path: "lib/ruby/popen.rb",
              old_line: nil,
              new_line: 9
            )
          end

          it 'only shows the new path and position in the note' do
            expect(returned_record.note).to eq(<<~COMMENT.strip)
              *Comment on lib/ruby/popen.rb:9*

              About this line...
            COMMENT
          end
        end

        context 'when the new path and position do not exist' do
          let_it_be(:position) do
            Gitlab::Diff::Position.new(
              old_path: "files/ruby/popen.rb",
              new_path: nil,
              old_line: 8,
              new_line: nil
            )
          end

          it 'only shows the old path and position in the note' do
            expect(returned_record.note).to eq(<<~COMMENT.strip)
              *Comment on files/ruby/popen.rb:8 -->*

              About this line...
            COMMENT
          end
        end
      end

      context 'when diff line is not found' do
        before do
          diff_file_stub = instance_double(Gitlab::Diff::File)
          allow(diff_file_stub).to receive_messages(line_for_position: nil, file_path: 'lib/ruby/popen.rb')
          allow(record).to receive(:fetch_diff_file).and_return(diff_file_stub)
        end

        it 'builds a new DiscussionNote' do
          recover_invalid_record

          # Ensure the context is correct
          expect(record.errors[:base]).to include(/Failed to find diff line for.*/)
          expect(record.errors[:base]).not_to include(DiffNote::DIFF_FILE_NOT_FOUND_MESSAGE)

          expect(returned_record).not_to eq(record)
          expect(returned_record).to be_a(DiscussionNote)
        end
      end

      context 'when the diff note is valid' do
        let(:record) do
          build(
            :diff_note_on_merge_request, position: position, original_position: position,
            project: merge_request.project, noteable: merge_request,
            line_code: "8ec9a00bfd09b3190ac6b22251dbb1aa95a0579d_4_7"
          )
        end

        it 'returns the same record' do
          expect(record).to be_valid

          expect(returned_record).to eq(record)
        end
      end

      context 'when the diff note is invalid due to a reason other than missing diff_file/diff_line' do
        let(:record) { build(:diff_note_on_merge_request, noteable_type: User) } # Not a valid notable type

        it 'returns the same record' do
          expect(record).not_to be_valid

          expect(returned_record).to eq(record)
        end
      end

      it 'instanciates a preparer' do
        expect(described_class).to receive(:new).with(record).and_call_original

        recover_invalid_record
      end
    end

    context 'when record is not a supported type' do
      let(:record) { build(:issue) }

      it 'returns the provided record' do
        expect(record).to be_valid

        expect(returned_record).to eq(record)
      end

      it 'does not instanciate a preparer' do
        expect(described_class).not_to receive(:new)

        recover_invalid_record
      end
    end
  end
end
