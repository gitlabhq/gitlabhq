# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Suggestions::ApplyService do
  include ProjectForksHelper

  def build_position(**optional_args)
    args = { old_path: "files/ruby/popen.rb",
             new_path: "files/ruby/popen.rb",
             old_line: nil,
             new_line: 9,
             diff_refs: merge_request.diff_refs,
             **optional_args }

    Gitlab::Diff::Position.new(args)
  end

  def create_suggestion(args)
    position_args = args.slice(:old_path, :new_path, :old_line, :new_line)
    content_args = args.slice(:from_content, :to_content)

    position = build_position(**position_args)

    diff_note = create(:diff_note_on_merge_request,
                       noteable: merge_request,
                       position: position,
                       project: project)

    suggestion_args = { note: diff_note }.merge(content_args)

    create(:suggestion, :content_from_repo, suggestion_args)
  end

  def apply(suggestions, custom_message = nil)
    result = apply_service.new(user, *suggestions, message: custom_message).execute

    suggestions.map { |suggestion| suggestion.reload }

    expect(result[:status]).to eq(:success)
  end

  shared_examples 'successfully creates commit and updates suggestions' do
    it 'updates the files with the new content' do
      apply(suggestions)

      suggestions.each do |suggestion|
        path = suggestion.diff_file.file_path
        blob = project.repository.blob_at_branch(merge_request.source_branch,
                                                 path)

        expect(blob.data).to eq(expected_content_by_path[path.to_sym])
      end
    end

    it 'updates suggestion applied and commit_id columns' do
      expect(suggestions.map(&:applied)).to all(be false)
      expect(suggestions.map(&:commit_id)).to all(be nil)

      apply(suggestions)

      expect(suggestions.map(&:applied)).to all(be true)
      expect(suggestions.map(&:commit_id)).to all(be_present)
    end

    it 'created commit has users email and name' do
      apply(suggestions)

      commit = project.repository.commit
      author = suggestions.first.note.author

      expect(user.commit_email).not_to eq(user.email)
      expect(commit.author_email).to eq(author.commit_email)
      expect(commit.committer_email).to eq(user.commit_email)
      expect(commit.author_name).to eq(author.name)
      expect(commit.committer_name).to eq(user.name)
    end

    it 'tracks apply suggestion event' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_apply_suggestion_action)
        .with(user: user)

      apply(suggestions)
    end

    context 'when a custom suggestion commit message' do
      before do
        project.update!(suggestion_commit_message: message)

        apply(suggestions)
      end

      context 'is not specified' do
        let(:message) { '' }

        it 'uses the default commit message' do
          expect(project.repository.commit.message).to(
            match(/\AApply #{suggestions.size} suggestion\(s\) to \d+ file\(s\)\z/)
          )
        end
      end

      context 'is specified' do
        let(:message) do
          'refactor: %{project_name} %{branch_name} %{username}'
        end

        it 'generates a custom commit message' do
          expect(project.repository.commit.message).to(
            eq("refactor: Project_1 master test.user")
          )
        end
      end
    end

    context 'with a user suggested commit message' do
      let(:message) { "i'm a custom commit message!" }

      it "uses the user's commit message" do
        apply(suggestions, message)

        expect(project.repository.commit.message).to(eq(message))
      end
    end
  end

  subject(:apply_service) { described_class }

  let_it_be(:user) do
    create(:user, :commit_email, name: 'Test User', username: 'test.user')
  end

  let(:project) do
    create(:project, :repository, path: 'project-1', name: 'Project_1')
  end

  let(:merge_request) do
    create(:merge_request, source_project: project,
           target_project: project,
           source_branch: 'master')
  end

  let(:position) { build_position }

  let(:diff_note) do
    create(:diff_note_on_merge_request, noteable: merge_request,
           position: position, project: project)
  end

  let(:suggestion) do
    create(:suggestion, :content_from_repo, note: diff_note,
           to_content: "      raise RuntimeError, 'Explosion'\n      # explosion?\n")
  end

  let(:suggestion2) do
    create_suggestion(
      to_content: "      *** SUGGESTION CHANGE ***\n",
      new_line: 15)
  end

  let(:suggestion3) do
    create_suggestion(
      to_content: "      *** ANOTHER SUGGESTION CHANGE ***\n",
      old_path: "files/ruby/regex.rb",
      new_path: "files/ruby/regex.rb",
      new_line: 22)
  end

  let(:suggestions) { [suggestion, suggestion2, suggestion3] }

  context 'patch is appliable' do
    let(:popen_content) do
      <<-CONTENT.strip_heredoc
        require 'fileutils'
        require 'open3'

        module Popen
          extend self

          def popen(cmd, path=nil)
            unless cmd.is_a?(Array)
              raise RuntimeError, 'Explosion'
              # explosion?
            end

            path ||= Dir.pwd

            vars = {
              *** SUGGESTION CHANGE ***
            }

            options = {
              chdir: path
            }

            unless File.directory?(path)
              FileUtils.mkdir_p(path)
            end

            @cmd_output = ""
            @cmd_status = 0

            Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
              @cmd_output << stdout.read
              @cmd_output << stderr.read
              @cmd_status = wait_thr.value.exitstatus
            end

            return @cmd_output, @cmd_status
          end
        end
      CONTENT
    end

    let(:regex_content) do
      <<-CONTENT.strip_heredoc
        module Gitlab
          module Regex
            extend self

            def username_regex
              default_regex
            end

            def project_name_regex
              /\\A[a-zA-Z0-9][a-zA-Z0-9_\\-\\. ]*\\z/
            end

            def name_regex
              /\\A[a-zA-Z0-9_\\-\\. ]*\\z/
            end

            def path_regex
              default_regex
            end

            def archive_formats_regex
              *** ANOTHER SUGGESTION CHANGE ***
            end

            def git_reference_regex
              # Valid git ref regex, see:
              # https://www.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
              %r{
                (?!
                   (?# doesn't begins with)
                   \\/|                    (?# rule #6)
                   (?# doesn't contain)
                   .*(?:
                      [\\\/.]\\\.|            (?# rule #1,3)
                      \\/\\/|               (?# rule #6)
                      @\\{|                (?# rule #8)
                      \\\\                  (?# rule #9)
                   )
                )
                [^\\000-\\040\\177~^:?*\\[]+  (?# rule #4-5)
                (?# doesn't end with)
                (?<!\\.lock)               (?# rule #1)
                (?<![\\/.])                (?# rule #6-7)
              }x
            end

            protected

            def default_regex
              /\\A[.?]?[a-zA-Z0-9][a-zA-Z0-9_\\-\\.]*(?<!\\.git)\\z/
            end
          end
        end
      CONTENT
    end

    let(:expected_content_by_path) do
      {
        "files/ruby/popen.rb": popen_content,
        "files/ruby/regex.rb": regex_content
      }
    end

    context 'non-fork project' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'successfully creates commit and updates suggestions'

      context 'when it fails to apply because a file was changed' do
        before do
          params = {
            file_path: suggestion3.diff_file.file_path,
            start_branch: suggestion3.branch,
            branch_name: suggestion3.branch,
            commit_message: 'Update file',
            file_content: 'New content'
          }

          # Reload the suggestion so it's memoized values get reset after the
          # file was changed.
          suggestion3.reload

          Files::UpdateService.new(project, user, params).execute
        end

        it 'returns error message' do
          result = apply_service.new(user, suggestion, suggestion3, suggestion2).execute

          expect(result).to eq(message: 'A file has been changed.', status: :error)
        end
      end

      context 'when HEAD from position is different from source branch HEAD on repo' do
        it 'returns error message' do
          allow(suggestion).to receive(:appliable?) { true }
          allow(suggestion.position).to receive(:head_sha) { 'old-sha' }
          allow(suggestion.noteable).to receive(:source_branch_sha) { 'new-sha' }

          result = apply_service.new(user, suggestion).execute

          expect(result).to eq(message: 'A file has been changed.', status: :error)
        end
      end

      context 'single suggestion' do
        let(:author) { suggestions.first.note.author }
        let(:commit) { project.repository.commit }

        context 'author of suggestion applies suggestion' do
          before do
            suggestion.note.update!(author_id: user.id)

            apply(suggestions)
          end

          it 'created commit by same author and committer' do
            expect(user.commit_email).to eq(author.commit_email)
            expect(author).to eq(user)
            expect(commit.author_email).to eq(author.commit_email)
            expect(commit.committer_email).to eq(user.commit_email)
            expect(commit.author_name).to eq(author.name)
            expect(commit.committer_name).to eq(user.name)
          end
        end

        context 'another user applies suggestion' do
          before do
            apply(suggestions)
          end

          it 'created commit has authors info and commiters info' do
            expect(user.commit_email).not_to eq(user.email)
            expect(author).not_to eq(user)
            expect(commit.author_email).to eq(author.commit_email)
            expect(commit.committer_email).to eq(user.commit_email)
            expect(commit.author_name).to eq(author.name)
            expect(commit.committer_name).to eq(user.name)
          end
        end
      end

      context 'multiple suggestions' do
        let(:author_emails) { suggestions.map {|s| s.note.author.commit_email } }
        let(:first_author) { suggestion.note.author }
        let(:commit) { project.repository.commit }

        context 'when all the same author' do
          before do
            apply(suggestions)
          end

          it 'uses first authors information' do
            expect(author_emails).to include(first_author.commit_email).exactly(3)
            expect(commit.author_email).to eq(first_author.commit_email)
          end
        end

        context 'when all different authors' do
          before do
            suggestion2.note.update!(author_id: create(:user).id)
            suggestion3.note.update!(author_id: create(:user).id)
            apply(suggestions)
          end

          it 'uses committers information' do
            expect(commit.author_email).to eq(user.commit_email)
            expect(commit.committer_email).to eq(user.commit_email)
          end
        end
      end

      context 'multiple suggestions applied sequentially' do
        def apply_suggestion(suggestion)
          suggestion.reload
          merge_request.reload
          merge_request.clear_memoized_shas

          result = apply_service.new(user, suggestion).execute
          suggestion.reload
          expect(result[:status]).to eq(:success)

          refresh = MergeRequests::RefreshService.new(project: project, current_user: user)
          refresh.execute(merge_request.diff_head_sha,
                          suggestion.commit_id,
                          merge_request.source_branch_ref)

          result
        end

        def fetch_raw_diff(suggestion)
          project.reload.commit(suggestion.commit_id)
            .diffs.diff_files.first.diff.diff
        end

        it 'applies multiple suggestions in subsequent versions correctly' do
          suggestion1 = create_suggestion(
            from_content: "\n",
            to_content: "# v1 change\n",
            old_line: nil,
            new_line: 13)

          suggestion2 = create_suggestion(
            from_content: "      @cmd_output << stderr.read\n",
            to_content: "# v2 change\n",
            old_line: 24,
            new_line: 31)

          apply_suggestion(suggestion1)
          apply_suggestion(suggestion2)

          suggestion1_diff = fetch_raw_diff(suggestion1)
          suggestion2_diff = fetch_raw_diff(suggestion2)

          # rubocop: disable Layout/TrailingWhitespace
          expected_suggestion1_diff = <<-CONTENT.strip_heredoc
            @@ -10,7 +10,7 @@ module Popen
                 end
             
                 path ||= Dir.pwd
            -
            +# v1 change
                 vars = {
                   "PWD" => path
                 }
          CONTENT
          # rubocop: enable Layout/TrailingWhitespace

          # rubocop: disable Layout/TrailingWhitespace
          expected_suggestion2_diff = <<-CONTENT.strip_heredoc
            @@ -28,7 +28,7 @@ module Popen
             
                 Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                   @cmd_output << stdout.read
            -      @cmd_output << stderr.read
            +# v2 change
                   @cmd_status = wait_thr.value.exitstatus
                 end
          CONTENT
          # rubocop: enable Layout/TrailingWhitespace

          expect(suggestion1_diff.strip).to eq(expected_suggestion1_diff.strip)
          expect(suggestion2_diff.strip).to eq(expected_suggestion2_diff.strip)
        end
      end

      context 'multi-line suggestion' do
        let(:popen_content) do
          <<~CONTENT.strip_heredoc
            require 'fileutils'
            require 'open3'

            module Popen
              extend self

            # multi
            # line

                vars = {
                  "PWD" => path
                }

                options = {
                  chdir: path
                }

                unless File.directory?(path)
                  FileUtils.mkdir_p(path)
                end

                @cmd_output = ""
                @cmd_status = 0

                Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                  @cmd_output << stdout.read
                  @cmd_output << stderr.read
                  @cmd_status = wait_thr.value.exitstatus
                end

                return @cmd_output, @cmd_status
              end
            end
          CONTENT
        end

        let(:expected_content_by_path) do
          {
            "files/ruby/popen.rb": popen_content
          }
        end

        let(:suggestion) do
          create(:suggestion, :content_from_repo, note: diff_note,
                 lines_above: 2,
                 lines_below: 3,
                 to_content: "# multi\n# line\n")
        end

        let(:suggestions) { [suggestion] }

        it_behaves_like 'successfully creates commit and updates suggestions'
      end

      context 'remove an empty line suggestion' do
        let(:popen_content) do
          <<~CONTENT.strip_heredoc
            require 'fileutils'
            require 'open3'

            module Popen
              extend self

              def popen(cmd, path=nil)
                unless cmd.is_a?(Array)
                  raise RuntimeError, "System commands must be given as an array of strings"
                end

                path ||= Dir.pwd
                vars = {
                  "PWD" => path
                }

                options = {
                  chdir: path
                }

                unless File.directory?(path)
                  FileUtils.mkdir_p(path)
                end

                @cmd_output = ""
                @cmd_status = 0

                Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                  @cmd_output << stdout.read
                  @cmd_output << stderr.read
                  @cmd_status = wait_thr.value.exitstatus
                end

                return @cmd_output, @cmd_status
              end
            end
          CONTENT
        end

        let(:expected_content_by_path) do
          {
            "files/ruby/popen.rb": popen_content
          }
        end

        let(:suggestion) do
          create_suggestion( to_content: "", new_line: 13)
        end

        let(:suggestions) { [suggestion] }

        it_behaves_like 'successfully creates commit and updates suggestions'
      end
    end

    context 'fork-project' do
      let(:project) { create(:project, :public, :repository) }

      let(:forked_project) do
        fork_project_with_submodules(project,
                                     user, repository: project.repository)
      end

      let(:merge_request) do
        create(:merge_request,
               source_branch: 'conflict-resolvable-fork',
               source_project: forked_project,
               target_branch: 'conflict-start',
               target_project: project)
      end

      let!(:diff_note) do
        create(:diff_note_on_merge_request,
               noteable: merge_request,
               position: position,
               project: project)
      end

      before do
        project.add_maintainer(user)
      end

      it 'updates file in the source project' do
        expect(Files::MultiService).to receive(:new)
                                         .with(merge_request.source_project,
                                               user,
                                               anything).and_call_original

        apply_service.new(user, suggestion).execute
      end
    end
  end

  context 'no permission' do
    let(:merge_request) do
      create(:merge_request, source_project: project,
             target_project: project)
    end

    let(:diff_note) do
      create(:diff_note_on_merge_request, noteable: merge_request,
             position: position,
             project: project)
    end

    context 'user cannot write in project repo' do
      before do
        project.add_reporter(user)
      end

      it 'returns error' do
        result = apply_service.new(user, suggestion).execute

        expect(result).to eq(message: "You are not allowed to push into this branch",
                             status: :error)
      end
    end
  end

  context 'patch is not appliable' do
    let(:merge_request) do
      create(:merge_request, source_project: project,
             target_project: project)
    end

    let(:diff_note) do
      create(:diff_note_on_merge_request, noteable: merge_request,
             position: position,
             project: project)
    end

    before do
      project.add_maintainer(user)
    end

    shared_examples_for 'service not tracking apply suggestion event' do
      it 'does not track apply suggestion event' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_apply_suggestion_action)

        result
      end
    end

    context 'diff file was not found' do
      let(:result) { apply_service.new(user, suggestion).execute }

      before do
        expect(suggestion.note).to receive(:latest_diff_file) { nil }
      end

      it 'returns error message' do
        expect(result).to eq(message: 'A file was not found.',
                             status: :error)
      end

      it_behaves_like 'service not tracking apply suggestion event'
    end

    context 'when not all suggestions belong to the same branch' do
      let(:merge_request2) do
        create(
          :merge_request,
          :conflict,
          source_project: project,
          target_project: project
        )
      end

      let(:position2) do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: 15,
          diff_refs: merge_request2.diff_refs
        )
      end

      let(:diff_note2) do
        create(
          :diff_note_on_merge_request,
          noteable: merge_request2,
          position: position2,
          project: project
        )
      end

      let(:other_branch_suggestion) { create(:suggestion, note: diff_note2) }
      let(:result) { apply_service.new(user, suggestion, other_branch_suggestion).execute }

      it 'renders error message' do
        expect(result).to eq(message: 'Suggestions must all be on the same branch.',
                             status: :error)
      end

      it_behaves_like 'service not tracking apply suggestion event'
    end

    context 'suggestion is not appliable' do
      let(:inapplicable_reason) { "Can't apply this suggestion." }
      let(:result) { apply_service.new(user, suggestion).execute }

      before do
        expect(suggestion).to receive(:appliable?).and_return(false)
        expect(suggestion).to receive(:inapplicable_reason).and_return(inapplicable_reason)
      end

      it 'returns error message' do
        expect(result).to eq(message: inapplicable_reason, status: :error)
      end

      it_behaves_like 'service not tracking apply suggestion event'
    end

    context 'lines of suggestions overlap' do
      let(:suggestion) do
        create_suggestion(
          to_content: "      raise RuntimeError, 'Explosion'\n      # explosion?\n")
      end

      let(:overlapping_suggestion) do
        create_suggestion(to_content: "I Overlap!")
      end

      let(:result) { apply_service.new(user, suggestion, overlapping_suggestion).execute }

      it 'returns error message' do
        expect(result).to eq(message: 'Suggestions are not applicable as their lines cannot overlap.',
                             status: :error)
      end

      it_behaves_like 'service not tracking apply suggestion event'
    end
  end
end
