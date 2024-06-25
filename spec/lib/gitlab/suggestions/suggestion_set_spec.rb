# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Suggestions::SuggestionSet do
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  def create_suggestion(file_path, new_line, to_content)
    position = Gitlab::Diff::Position.new(old_path: file_path,
      new_path: file_path,
      old_line: nil,
      new_line: new_line,
      diff_refs: merge_request.diff_refs)

    diff_note = create(:diff_note_on_merge_request,
      noteable: merge_request,
      position: position,
      project: project)

    create(:suggestion,
      :content_from_repo,
      note: diff_note,
      to_content: to_content)
  end

  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:forked_project) { fork_project(project, nil, repository: true) }

  let_it_be(:merge_request_same_project) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:merge_request_from_fork) do
    create(:merge_request, source_project: forked_project, target_project: project)
  end

  where(:merge_request) { [ref(:merge_request_same_project), ref(:merge_request_from_fork)] }
  with_them do
    let(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request) }
    let(:suggestion) { create(:suggestion, note: note) }

    let(:suggestion2) do
      create_suggestion('files/ruby/popen.rb', 13, "*** SUGGESTION 2 ***")
    end

    let(:suggestion3) do
      create_suggestion('files/ruby/regex.rb', 22, "*** SUGGESTION 3 ***")
    end

    let(:unappliable_suggestion) { create(:suggestion, :unappliable) }

    let(:suggestion_set) { described_class.new([suggestion]) }

    describe '#source_project' do
      it 'returns the source project associated with the suggestions' do
        expect(suggestion_set.source_project).to be(merge_request.source_project)
      end
    end

    describe '#target_project' do
      it 'returns the target project associated with the suggestions' do
        expect(suggestion_set.target_project).to be(project)
      end
    end

    describe '#branch' do
      it 'returns the branch associated with the suggestions' do
        expected_branch = suggestion.branch

        expect(suggestion_set.branch).to be(expected_branch)
      end
    end

    describe '#valid?' do
      it 'returns true if no errors are found' do
        expect(suggestion_set.valid?).to be(true)
      end

      it 'returns false if an error is found' do
        suggestion_set = described_class.new([unappliable_suggestion])

        expect(suggestion_set.valid?).to be(false)
      end
    end

    describe '#error_message' do
      it 'returns an error message if an error is found' do
        suggestion_set = described_class.new([unappliable_suggestion])

        expect(suggestion_set.error_message).to be_a(String)
      end

      it 'returns nil if no errors are found' do
        expect(suggestion_set.error_message).to be(nil)
      end
    end

    describe '#actions' do
      it 'returns an array of hashes with proper key/value pairs' do
        first_action = suggestion_set.actions.first

        file_suggestion = suggestion_set.send(:suggestions_per_file).first

        expect(first_action[:action]).to be('update')
        expect(first_action[:file_path]).to eq(file_suggestion.file_path)
        expect(first_action[:content]).to eq(file_suggestion.new_content)
      end
    end

    describe '#file_paths' do
      it 'returns an array of unique file paths associated with the suggestions' do
        suggestion_set = described_class.new([suggestion, suggestion2, suggestion3])

        expected_paths = %w[files/ruby/popen.rb files/ruby/regex.rb]

        actual_paths = suggestion_set.file_paths

        expect(actual_paths.sort).to eq(expected_paths)
      end
    end
  end
end
