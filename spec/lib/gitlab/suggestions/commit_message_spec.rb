# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Suggestions::CommitMessage, feature_category: :code_review_workflow do
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  def create_suggestion(merge_request, file_path, new_line, to_content, author)
    position = Gitlab::Diff::Position.new(old_path: file_path,
      new_path: file_path,
      old_line: nil,
      new_line: new_line,
      diff_refs: merge_request.diff_refs)

    diff_note = create(:diff_note_on_merge_request,
      noteable: merge_request,
      author: author,
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

  let_it_be(:forked_project) { fork_project(project, nil, repository: true) }

  let_it_be(:merge_request_same_project) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:merge_request_from_fork) do
    create(:merge_request, source_project: forked_project, target_project: project)
  end

  let_it_be(:first_author) { merge_request_same_project.author }

  let_it_be(:second_author) do
    merge_request_from_fork.author.tap do |author|
      author.commit_email = author.verified_emails.last
    end
  end

  let_it_be(:suggestion_set_same_project) do
    suggestion1 = create_suggestion(
      merge_request_same_project, 'files/ruby/popen.rb', 9, '*** SUGGESTION 1 ***', user
    )
    suggestion2 = create_suggestion(
      merge_request_same_project, 'files/ruby/popen.rb', 13, '*** SUGGESTION 2 ***', first_author
    )
    suggestion3 = create_suggestion(
      merge_request_same_project, 'files/ruby/regex.rb', 22, '*** SUGGESTION 3 ***', second_author
    )

    Gitlab::Suggestions::SuggestionSet.new([suggestion1, suggestion2, suggestion3])
  end

  let_it_be(:suggestion_set_forked_project) do
    suggestion1 = create_suggestion(
      merge_request_from_fork, 'files/ruby/popen.rb', 9, '*** SUGGESTION 1 ***', user
    )
    suggestion2 = create_suggestion(
      merge_request_from_fork, 'files/ruby/popen.rb', 13, '*** SUGGESTION 2 ***', first_author
    )
    suggestion3 = create_suggestion(
      merge_request_from_fork, 'files/ruby/regex.rb', 22, '*** SUGGESTION 3 ***', second_author
    )

    Gitlab::Suggestions::SuggestionSet.new([suggestion1, suggestion2, suggestion3])
  end

  describe '#message' do
    where(:suggestion_set) { [ref(:suggestion_set_same_project), ref(:suggestion_set_forked_project)] }

    with_them do
      before do
        # Updating the suggestion_commit_message on a project shared across specs
        # avoids recreating the repository for each spec.
        project.update!(suggestion_commit_message: message)
        forked_project.update!(suggestion_commit_message: fork_message)
      end

      let(:fork_message) { nil }

      context 'when a custom commit message is not specified' do
        let(:expected_message) do
          "Apply 3 suggestion(s) to 2 file(s)\n\n" \
            "Co-authored-by: #{first_author.name} <#{first_author.email}>\n" \
            "Co-authored-by: #{second_author.name} <#{second_author.commit_email}>"
        end

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

        context 'when a custom commit message is specified for forked project' do
          let(:message) { nil }
          let(:fork_message) { "I'm a sad message that will not be used :(" }

          it 'uses the default commit message' do
            expect(described_class
                     .new(user, suggestion_set)
                     .message).to eq(expected_message)
          end
        end
      end

      context 'when a custom commit message is specified' do
        let(:message) { "i'm a project message. a user's custom message takes precedence over me :(" }
        let(:custom_message) { "hello there! i'm a cool custom commit message." }

        it 'shows the custom commit message' do
          expect(Gitlab::Suggestions::CommitMessage
                  .new(user, suggestion_set, custom_message)
                  .message).to eq(custom_message)
        end
      end

      context 'is specified and includes all placeholders' do
        let(:suggestion_author) { suggestion_set.authors.first }
        let(:message) do
          <<~MESSAGE
          ***
          %{branch_name} %{files_count} %{file_paths}
          %{project_name} %{project_path} %{user_full_name}
          %{username} %{suggestions_count}

          %{co_authored_by}
          ***
          MESSAGE
        end

        it 'generates a custom commit message' do
          expect(Gitlab::Suggestions::CommitMessage
                  .new(user, suggestion_set)
                  .message).to eq(
                    <<~MESSAGE
                  ***
                  master 2 files/ruby/popen.rb, files/ruby/regex.rb
                  Project_1 project-1 Test User
                  test.user 3

                  Co-authored-by: #{first_author.name} <#{first_author.email}>
                  Co-authored-by: #{second_author.name} <#{second_author.commit_email}>
                  ***
                    MESSAGE
                  )
        end

        context 'when a custom commit message is specified for forked project' do
          let(:fork_message) { "I'm a sad message that will not be used :(" }

          it 'uses the target project commit message' do
            expect(Gitlab::Suggestions::CommitMessage
                    .new(user, suggestion_set)
                    .message).to eq(
                      <<~MESSAGE
                      ***
                      master 2 files/ruby/popen.rb, files/ruby/regex.rb
                      Project_1 project-1 Test User
                      test.user 3

                      Co-authored-by: #{first_author.name} <#{first_author.email}>
                      Co-authored-by: #{second_author.name} <#{second_author.commit_email}>
                      ***
                      MESSAGE
                    )
          end
        end
      end
    end
  end
end
