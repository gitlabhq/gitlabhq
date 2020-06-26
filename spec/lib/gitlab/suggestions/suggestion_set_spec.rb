# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Suggestions::SuggestionSet do
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

  let_it_be(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:suggestion) { create(:suggestion)}

  let_it_be(:suggestion2) do
    create_suggestion('files/ruby/popen.rb', 13, "*** SUGGESTION 2 ***")
  end

  let_it_be(:suggestion3) do
    create_suggestion('files/ruby/regex.rb', 22, "*** SUGGESTION 3 ***")
  end

  let_it_be(:unappliable_suggestion) { create(:suggestion, :unappliable) }

  let(:suggestion_set) { described_class.new([suggestion]) }

  describe '#project' do
    it 'returns the project associated with the suggestions' do
      expected_project = suggestion.project

      expect(suggestion_set.project).to be(expected_project)
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

      expected_paths = %w(files/ruby/popen.rb files/ruby/regex.rb)

      actual_paths = suggestion_set.file_paths

      expect(actual_paths.sort).to eq(expected_paths)
    end
  end
end
