# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::DiffNoteImporter, :aggregate_failures, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(
      :project, :repository, :in_group, :github_import,
      :import_user_mapping_enabled
    )
  end

  let_it_be(:user) { create(:user) }

  let(:client) { instance_double(Gitlab::GithubImport::Client, web_endpoint: 'https://github.com') }
  let(:discussion_id) { 'b0fa404393eeebb4e82becb8104f238812bb1fe6' }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00).utc }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15).utc }
  let(:note_body) { 'Hello' }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:end_line) { 15 }

  let(:diff_hunk) do
    '@@ -14 +14 @@
    -Hello
    +Hello world'
  end

  let(:note_representation) do
    Gitlab::GithubImport::Representation::DiffNote.new(
      noteable_type: 'MergeRequest',
      noteable_id: 1,
      commit_id: '123abc',
      original_commit_id: 'original123abc',
      file_path: file_path,
      author: Gitlab::GithubImport::Representation::User.new(id: user.id, login: user.username),
      note: note_body,
      created_at: created_at,
      updated_at: updated_at,
      start_line: nil,
      end_line: end_line,
      github_id: 1,
      diff_hunk: diff_hunk,
      side: 'RIGHT',
      discussion_id: discussion_id
    )
  end

  let(:cached_references) { placeholder_user_references(::Import::SOURCE_GITHUB, project.import_state.id) }

  subject(:importer) { described_class.new(note_representation, project, client) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when user mapping is enabled' do
      let_it_be(:source_user) { generate_source_user(project, user.id) }

      context 'when the merge request no longer exists' do
        it 'does not import anything' do
          expect(ApplicationRecord).not_to receive(:legacy_bulk_insert)

          expect { subject.execute }
            .to not_change(DiffNote, :count)
            .and not_change(LegacyDiffNote, :count)
        end
      end

      context 'when the merge request exists' do
        let_it_be(:merge_request) do
          create(:merge_request, source_project: project, target_project: project)
        end

        before do
          expect_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
            expect(finder)
              .to receive(:database_id)
              .and_return(merge_request.id)
          end
        end

        it 'pushes placeholder references' do
          subject.execute

          expect(cached_references).to contain_exactly(
            ['LegacyDiffNote', instance_of(Integer), 'author_id', source_user.id]
          )
        end

        it 'imports the note as legacy diff note' do
          expect { subject.execute }
            .to change(LegacyDiffNote, :count)
            .by(1)

          note = project.notes.diff_notes.take
          expect(note).to be_valid
          expect(note.imported_from).to eq(::Import::SOURCE_GITHUB.to_s)
          expect(note.author_id).to eq(source_user.mapped_user_id)
          expect(note.commit_id).to eq('original123abc')
          expect(note.created_at).to eq(created_at)
          expect(note.diff).to be_an_instance_of(Gitlab::Git::Diff)
          expect(note.discussion_id).to eq(discussion_id)
          expect(note.line_code).to eq(note_representation.line_code)
          expect(note.note).to eq('Hello')
          expect(note.noteable_id).to eq(merge_request.id)
          expect(note.noteable_type).to eq('MergeRequest')
          expect(note.project_id).to eq(project.id)
          expect(note.st_diff).to eq(note_representation.diff_hash)
          expect(note.system).to eq(false)
          expect(note.type).to eq('LegacyDiffNote')
          expect(note.updated_at).to eq(updated_at)
        end

        context 'when the note body includes @ mentions' do
          let(:note_body) { "I said to @sam_allen\0 the code should follow @bob's\0 advice. @.ali-ce/group#9?\0" }
          let(:expected_note_body) { "I said to `@sam_allen` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?" }

          it 'formats the text correctly' do
            subject.execute

            note = project.notes.diff_notes.take
            expect(note.note).to eq(expected_note_body)
          end
        end

        context 'when the note has suggestions' do
          let(:note_body) do
            <<~EOB
            Suggestion:
            ```suggestion
            what do you think to do it like this
            ```
            EOB
          end

          it 'pushes placeholder references' do
            subject.execute

            expect(cached_references).to contain_exactly(
              ['DiffNote', instance_of(Integer), 'author_id', source_user.id]
            )
          end

          it 'imports the note as diff note' do
            expect_next_instance_of(Import::Github::Notes::CreateService) do |service|
              expect(service).to receive(:execute).with(importing: true).and_call_original
            end

            expect { subject.execute }
              .to change(DiffNote, :count)
              .by(1)
              .and not_change(LegacyDiffNote, :count)

            note = project.notes.diff_notes.take
            expect(note).to be_valid
            expect(note.imported_from).to eq(::Import::SOURCE_GITHUB.to_s)
            expect(note.noteable_type).to eq('MergeRequest')
            expect(note.noteable_id).to eq(merge_request.id)
            expect(note.project_id).to eq(project.id)
            expect(note.namespace_id).to eq(project.project_namespace_id)
            expect(note.author_id).to eq(source_user.mapped_user_id)
            expect(note.system).to eq(false)
            expect(note.discussion_id).to eq(discussion_id)
            expect(note.commit_id).to eq('original123abc')
            expect(note.line_code).to eq(note_representation.line_code)
            expect(note.type).to eq('DiffNote')
            expect(note.created_at).to eq(created_at)
            expect(note.updated_at).to eq(updated_at)
            expect(note.position.to_h).to eq({
              base_sha: merge_request.diffs.diff_refs.base_sha,
              head_sha: merge_request.diffs.diff_refs.head_sha,
              start_sha: merge_request.diffs.diff_refs.start_sha,
              new_line: 15,
              old_line: nil,
              new_path: file_path,
              old_path: file_path,
              position_type: 'text',
              line_range: nil,
              ignore_whitespace_change: false
            })
            expect(note.note)
              .to eq <<~NOTE
              Suggestion:
              ```suggestion:-0+0
              what do you think to do it like this
              ```
              NOTE
          end

          context 'when the note diff file creation fails with DiffNoteCreationError due to outdated suggestion' do
            let(:end_line) { nil }

            it 'falls back to the LegacyDiffNote' do
              expect(Gitlab::GithubImport::Logger)
                .to receive(:warn)
                      .with(
                        {
                          message: "Validation failed: Line code can't be blank, Line code must be a valid line code, Position is incomplete",
                          'error.class': 'Gitlab::GithubImport::Importer::DiffNoteImporter::DiffNoteCreationError'
                        }
                      )

              expect { subject.execute }
                .to change(LegacyDiffNote, :count)
                      .and not_change(DiffNote, :count)
            end
          end

          context 'when the note diff file creation fails with NoteDiffFileCreationError' do
            it 'falls back to the LegacyDiffNote' do
              exception = ::DiffNote::NoteDiffFileCreationError.new('Failed to create diff note file')

              expect_next_instance_of(::Import::Github::Notes::CreateService) do |service|
                expect(service)
                  .to receive(:execute)
                  .and_raise(exception)
              end

              expect(Gitlab::GithubImport::Logger)
                .to receive(:warn)
                .with(
                  {
                    message: 'Failed to create diff note file',
                    'error.class': 'DiffNote::NoteDiffFileCreationError'
                  }
                )

              expect { subject.execute }
                .to change(LegacyDiffNote, :count)
                .and not_change(DiffNote, :count)
            end
          end

          context 'when direct reassignment is supported' do
            before do
              allow(Import::DirectReassignService).to receive(:supported?).and_return(true)
            end

            it 'does not push any placeholder references' do
              subject.execute

              expect(cached_references).to be_empty
            end
          end

          context 'when importing into a personal namespace' do
            let_it_be(:user_namespace) { create(:namespace) }

            before_all do
              project.update!(namespace: user_namespace)
            end

            it 'does not push any references' do
              subject.execute

              expect(cached_references).to be_empty
            end

            it 'imports the diff note mapped to the personal namespace owner' do
              expect { subject.execute }
                .to change(DiffNote, :count)
                .by(1)

              note = project.notes.diff_notes.take
              expect(note.author_id).to eq(user_namespace.owner_id)
            end
          end
        end

        context 'when diff note is invalid' do
          it 'fails validation' do
            expect(note_representation).to receive(:line_code).and_return(nil)

            expect { subject.execute }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end

        context 'when direct reassignment is supported' do
          before do
            allow(Import::DirectReassignService).to receive(:supported?).and_return(true)
          end

          it 'does not push any placeholder references' do
            subject.execute

            expect(cached_references).to be_empty
          end
        end

        context 'when importing into a personal namespace' do
          let_it_be(:user_namespace) { create(:namespace) }
          let_it_be(:project) do
            project.update!(namespace: user_namespace)
            project
          end

          it 'does not push any references' do
            subject.execute

            expect(cached_references).to be_empty
          end

          it 'imports the legacy diff note mapped to the personal namespace owner' do
            expect { subject.execute }
              .to change(LegacyDiffNote, :count)
              .by(1)

            note = project.notes.diff_notes.take
            expect(note.author_id).to eq(user_namespace.owner_id)
          end
        end
      end
    end

    context 'when user mapping is disabled' do
      before_all do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      context 'when the merge request no longer exists' do
        it 'does not import anything' do
          expect(ApplicationRecord).not_to receive(:legacy_bulk_insert)

          expect { subject.execute }
            .to not_change(DiffNote, :count)
            .and not_change(LegacyDiffNote, :count)
        end
      end

      context 'when the merge request exists' do
        let_it_be(:merge_request) do
          create(:merge_request, source_project: project, target_project: project)
        end

        let(:gitlab_user_id) { user.id }

        before do
          expect_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
            expect(finder).to receive(:find).and_return(gitlab_user_id)
          end

          expect_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
            expect(finder)
              .to receive(:database_id)
              .and_return(merge_request.id)
          end
        end

        it 'does not push placeholder references' do
          subject.execute

          expect(cached_references).to be_empty
        end

        it 'imports the note as legacy diff note' do
          expect { subject.execute }
            .to change(LegacyDiffNote, :count)
            .by(1)

          note = project.notes.diff_notes.take
          expect(note).to be_valid
          expect(note.imported_from).to eq(::Import::SOURCE_GITHUB.to_s)
          expect(note.author_id).to eq(user.id)
          expect(note.commit_id).to eq('original123abc')
          expect(note.created_at).to eq(created_at)
          expect(note.diff).to be_an_instance_of(Gitlab::Git::Diff)
          expect(note.discussion_id).to eq(discussion_id)
          expect(note.line_code).to eq(note_representation.line_code)
          expect(note.note).to eq('Hello')
          expect(note.noteable_id).to eq(merge_request.id)
          expect(note.noteable_type).to eq('MergeRequest')
          expect(note.project_id).to eq(project.id)
          expect(note.st_diff).to eq(note_representation.diff_hash)
          expect(note.system).to eq(false)
          expect(note.type).to eq('LegacyDiffNote')
          expect(note.updated_at).to eq(updated_at)
        end

        context 'when the author is not found' do
          let(:gitlab_user_id) { nil }

          it 'sets the project creator as the author with a "created by:" note' do
            expect { subject.execute }
              .to change(LegacyDiffNote, :count)
              .by(1)

            note = project.notes.diff_notes.take
            expect(note).to be_valid
            expect(note.author_id).to eq(project.creator_id)
            expect(note.note).to eq("*Created by: #{user.username}*\n\nHello")
          end
        end

        context 'when the note has suggestions' do
          let(:note_body) do
            <<~EOB
            Suggestion:
            ```suggestion
            what do you think to do it like this
            ```
            EOB
          end

          it 'does not push placeholder references' do
            subject.execute

            expect(cached_references).to be_empty
          end

          it 'imports the note as diff note' do
            expect_next_instance_of(Import::Github::Notes::CreateService) do |service|
              expect(service).to receive(:execute).with(importing: true).and_call_original
            end

            expect { subject.execute }
              .to change(DiffNote, :count)
              .by(1)

            note = project.notes.diff_notes.take
            expect(note).to be_valid
            expect(note.imported_from).to eq(::Import::SOURCE_GITHUB.to_s)
            expect(note.noteable_type).to eq('MergeRequest')
            expect(note.noteable_id).to eq(merge_request.id)
            expect(note.project_id).to eq(project.id)
            expect(note.namespace_id).to eq(project.project_namespace_id)
            expect(note.author_id).to eq(user.id)
            expect(note.system).to eq(false)
            expect(note.discussion_id).to eq(discussion_id)
            expect(note.commit_id).to eq('original123abc')
            expect(note.line_code).to eq(note_representation.line_code)
            expect(note.type).to eq('DiffNote')
            expect(note.created_at).to eq(created_at)
            expect(note.updated_at).to eq(updated_at)
            expect(note.position.to_h).to eq({
              base_sha: merge_request.diffs.diff_refs.base_sha,
              head_sha: merge_request.diffs.diff_refs.head_sha,
              start_sha: merge_request.diffs.diff_refs.start_sha,
              new_line: 15,
              old_line: nil,
              new_path: file_path,
              old_path: file_path,
              position_type: 'text',
              line_range: nil,
              ignore_whitespace_change: false
            })
            expect(note.note)
              .to eq <<~NOTE
              Suggestion:
              ```suggestion:-0+0
              what do you think to do it like this
              ```
              NOTE
          end

          context 'when the note diff file creation fails with DiffNoteCreationError due to outdated suggestion' do
            let(:end_line) { nil }

            it 'falls back to the LegacyDiffNote' do
              expect(Gitlab::GithubImport::Logger)
                .to receive(:warn)
                      .with(
                        {
                          message: "Validation failed: Line code can't be blank, Line code must be a valid line code, Position is incomplete",
                          'error.class': 'Gitlab::GithubImport::Importer::DiffNoteImporter::DiffNoteCreationError'
                        }
                      )

              expect { subject.execute }
                .to change(LegacyDiffNote, :count)
                      .and not_change(DiffNote, :count)
            end
          end

          context 'when the note diff file creation fails with NoteDiffFileCreationError' do
            it 'falls back to the LegacyDiffNote' do
              exception = ::DiffNote::NoteDiffFileCreationError.new('Failed to create diff note file')

              expect_next_instance_of(::Import::Github::Notes::CreateService) do |service|
                expect(service)
                  .to receive(:execute)
                  .and_raise(exception)
              end

              expect(Gitlab::GithubImport::Logger)
                .to receive(:warn)
                .with(
                  {
                    message: 'Failed to create diff note file',
                    'error.class': 'DiffNote::NoteDiffFileCreationError'
                  }
                )

              expect { subject.execute }
                .to change(LegacyDiffNote, :count)
                .and not_change(DiffNote, :count)
            end
          end
        end

        context 'when diff note is invalid' do
          it 'fails validation' do
            expect(note_representation).to receive(:line_code).and_return(nil)

            expect { subject.execute }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
    end
  end
end
