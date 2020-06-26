# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Suggestions::CommitMessage do
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

  let_it_be(:user) do
    create(:user, :commit_email, name: 'Test User', username: 'test.user')
  end

  let_it_be(:project) do
    create(:project, :repository, path: 'project-1', name: 'Project_1')
  end

  let_it_be(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:suggestion_set) do
    suggestion1 = create_suggestion('files/ruby/popen.rb', 9, '*** SUGGESTION 1 ***')
    suggestion2 = create_suggestion('files/ruby/popen.rb', 13, '*** SUGGESTION 2 ***')
    suggestion3 = create_suggestion('files/ruby/regex.rb', 22, '*** SUGGESTION 3 ***')

    Gitlab::Suggestions::SuggestionSet.new([suggestion1, suggestion2, suggestion3])
  end

  describe '#message' do
    before do
      # Updating the suggestion_commit_message on a project shared across specs
      # avoids recreating the repository for each spec.
      project.update!(suggestion_commit_message: message)
    end

    context 'when a custom commit message is not specified' do
      let(:expected_message) { 'Apply 3 suggestion(s) to 2 file(s)' }

      context 'and is nil' do
        let(:message) { nil }

        it 'uses the default commit message' do
          expect(described_class
                   .new(user, suggestion_set)
                   .message).to eq(expected_message)
        end
      end

      context 'and is an empty string' do
        let(:message) { '' }

        it 'uses the default commit message' do
          expect(described_class
                   .new(user, suggestion_set)
                   .message).to eq(expected_message)
        end
      end
    end

    context 'is specified and includes all placeholders' do
      let(:message) do
        '*** %{branch_name} %{files_count} %{file_paths} %{project_name} %{project_path} %{user_full_name} %{username} %{suggestions_count} ***'
      end

      it 'generates a custom commit message' do
        expect(Gitlab::Suggestions::CommitMessage
                 .new(user, suggestion_set)
                 .message).to eq('*** master 2 files/ruby/popen.rb, files/ruby/regex.rb Project_1 project-1 Test User test.user 3 ***')
      end
    end
  end
end
