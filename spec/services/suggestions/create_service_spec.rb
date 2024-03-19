# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Suggestions::CreateService, feature_category: :code_review_workflow do
  let(:project_with_repo) { create(:project, :repository) }
  let(:merge_request) do
    create(
      :merge_request,
      source_project: project_with_repo,
      target_project: project_with_repo
    )
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

        ```suggestion:-3+2
          # multi-line suggestion 1
        ```

        ```suggestion:-5
          # multi-line suggestion 1
        ```
    MARKDOWN
  end

  subject { described_class.new(note) }

  shared_examples_for 'service not tracking add suggestion event' do
    it 'does not track add suggestion event' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .not_to receive(:track_add_suggestion_action)

      subject.execute
    end
  end

  describe '#execute' do
    context 'should not try to parse suggestions' do
      context 'when not a diff note for merge requests' do
        let(:note) do
          create(:diff_note_on_commit, project: project_with_repo, note: markdown)
        end

        it 'does not try to parse suggestions' do
          expect(Gitlab::Diff::SuggestionsParser).not_to receive(:parse)

          subject.execute
        end

        it_behaves_like 'service not tracking add suggestion event'
      end

      context 'when diff note is not for text' do
        let(:note) do
          create(
            :diff_note_on_merge_request,
            project: project_with_repo,
            noteable: merge_request,
            position: position,
            note: markdown
          )
        end

        before do
          allow(note).to receive(:on_text?) { false }
        end

        it 'does not try to parse suggestions' do
          expect(Gitlab::Diff::SuggestionsParser).not_to receive(:parse)

          subject.execute
        end

        it_behaves_like 'service not tracking add suggestion event'
      end
    end

    context 'when diff file is not found' do
      let(:note) do
        create(
          :diff_note_on_merge_request,
          project: project_with_repo,
          noteable: merge_request,
          position: position,
          note: markdown
        )
      end

      before do
        expect_next_instance_of(DiffNote) do |diff_note|
          expect(diff_note).to receive(:latest_diff_file).once { nil }
        end
      end

      it 'creates no suggestion' do
        expect { subject.execute }.not_to change(Suggestion, :count)
      end

      it_behaves_like 'service not tracking add suggestion event'
    end

    context 'should create suggestions' do
      let(:note) do
        create(
          :diff_note_on_merge_request,
          project: project_with_repo,
          noteable: merge_request,
          position: position,
          note: markdown
        )
      end

      let(:expected_suggestions) do
        Gitlab::Diff::SuggestionsParser.parse(
          markdown,
          project: note.project,
          position: note.position
        )
      end

      it 'persists suggestion records' do
        expect { subject.execute }.to change { note.suggestions.count }
          .from(0).to(expected_suggestions.size)
      end

      it 'persists suggestions data correctly' do
        subject.execute

        suggestions = note.suggestions.order(:relative_order)

        suggestions.zip(expected_suggestions) do |suggestion, expected_suggestion|
          expected_data = expected_suggestion.to_hash

          expect(suggestion.from_content).to eq(expected_data[:from_content])
          expect(suggestion.to_content).to eq(expected_data[:to_content])
          expect(suggestion.lines_above).to eq(expected_data[:lines_above])
          expect(suggestion.lines_below).to eq(expected_data[:lines_below])
        end
      end

      it 'tracks add suggestion event' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_add_suggestion_action)
          .with(note: note)

        subject.execute
      end

      context 'outdated position note' do
        let!(:outdated_diff) { merge_request.merge_request_diff }
        let!(:latest_diff) { merge_request.create_merge_request_diff }
        let(:outdated_position) { build_position(diff_refs: outdated_diff.diff_refs) }
        let(:position) { build_position(diff_refs: latest_diff.diff_refs) }

        it 'uses the correct position when creating the suggestion' do
          expect(Gitlab::Diff::SuggestionsParser).to receive(:parse)
            .with(note.note, project: note.project, position: note.position)
            .and_call_original

          subject.execute
        end
      end

      context 'when a patch removes an empty line' do
        let(:markdown) do
          <<-MARKDOWN.strip_heredoc
              ```suggestion
              ```
          MARKDOWN
        end

        let(:position) { build_position(new_line: 13) }

        it 'creates an appliable suggestion' do
          subject.execute

          suggestion = note.suggestions.last

          expect(suggestion).to be_appliable
          expect(suggestion.from_content).to eq("\n")
          expect(suggestion.to_content).to eq("")
        end
      end
    end
  end
end
