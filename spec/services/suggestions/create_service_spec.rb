# frozen_string_literal: true

require 'spec_helper'

describe Suggestions::CreateService do
  let(:project_with_repo) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request, source_project: project_with_repo,
                           target_project: project_with_repo)
  end

  def build_position(args = {})
    default_args = { old_path: "files/ruby/popen.rb",
                     new_path: "files/ruby/popen.rb",
                     old_line: nil,
                     new_line: 14,
                     diff_refs: merge_request.diff_refs }

    Gitlab::Diff::Position.new(default_args.merge(args))
  end

  let(:position) { build_position }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
        ```suggestion
          foo
          bar
        ```

        ```
          nothing
        ```

        ```suggestion
          xpto
          baz
        ```

        ```thing
          this is not a suggestion, it's a thing
        ```
    MARKDOWN
  end

  subject { described_class.new(note) }

  describe '#execute' do
    context 'should not try to parse suggestions' do
      context 'when not a diff note for merge requests' do
        let(:note) do
          create(:diff_note_on_commit, project: project_with_repo,
                                       note: markdown)
        end

        it 'does not try to parse suggestions' do
          expect(Banzai::SuggestionsParser).not_to receive(:parse)

          subject.execute
        end
      end

      context 'when diff note is not for text' do
        let(:note) do
          create(:diff_note_on_merge_request, project: project_with_repo,
                                              noteable: merge_request,
                                              position: position,
                                              note: markdown)
        end

        it 'does not try to parse suggestions' do
          allow(note).to receive(:on_text?) { false }

          expect(Banzai::SuggestionsParser).not_to receive(:parse)

          subject.execute
        end
      end
    end

    context 'should not create suggestions' do
      let(:note) do
        create(:diff_note_on_merge_request, project: project_with_repo,
                                            noteable: merge_request,
                                            position: position,
                                            note: markdown)
      end

      it 'creates no suggestion when diff file is not found' do
        expect(note).to receive(:latest_diff_file) { nil }

        expect { subject.execute }.not_to change(Suggestion, :count)
      end
    end

    context 'should create suggestions' do
      let(:note) do
        create(:diff_note_on_merge_request, project: project_with_repo,
                                            noteable: merge_request,
                                            position: position,
                                            note: markdown)
      end

      context 'single line suggestions' do
        it 'persists suggestion records' do
          expect { subject.execute }
            .to change { note.suggestions.count }
            .from(0)
            .to(2)
        end

        it 'persists original from_content lines and suggested lines' do
          subject.execute

          suggestions = note.suggestions.order(:relative_order)

          suggestion_1 = suggestions.first
          suggestion_2 = suggestions.last

          expect(suggestion_1).to have_attributes(from_content: "    vars = {\n",
                                                  to_content: "  foo\n  bar\n")

          expect(suggestion_2).to have_attributes(from_content: "    vars = {\n",
                                                  to_content: "  xpto\n  baz\n")
        end

        context 'outdated position note' do
          let!(:outdated_diff) { merge_request.merge_request_diff }
          let!(:latest_diff) { merge_request.create_merge_request_diff }
          let(:outdated_position) { build_position(diff_refs: outdated_diff.diff_refs) }
          let(:position) { build_position(diff_refs: latest_diff.diff_refs) }

          it 'uses the correct position when creating the suggestion' do
            expect(note.position)
              .to receive(:diff_file)
              .with(project_with_repo.repository)
              .and_call_original

            subject.execute
          end
        end
      end
    end
  end
end
