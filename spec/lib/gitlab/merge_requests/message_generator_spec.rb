# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::MessageGenerator, feature_category: :code_review_workflow do
  let(:merge_commit_template) { nil }
  let(:squash_commit_template) { nil }
  let(:project) do
    create(
      :project,
      :public,
      :repository,
      merge_commit_template: merge_commit_template,
      squash_commit_template: squash_commit_template
    )
  end

  let(:current_user) { create(:user, name: 'John Doe', email: 'john.doe@example.com') }
  let(:author) { current_user }
  let(:source_branch) { 'feature' }
  let(:merge_request_description) { "Merge Request Description\nNext line" }
  let(:merge_request_title) { 'Bugfix' }
  let(:merge_request) do
    create(
      :merge_request,
      :simple,
      source_project: project,
      target_project: project,
      target_branch: 'master',
      source_branch: source_branch,
      author: author,
      description: merge_request_description,
      title: merge_request_title
    )
  end

  subject { described_class.new(merge_request: merge_request, current_user: current_user) }

  shared_examples_for 'commit message with template' do |message_template_name|
    it 'returns nil when template is not set in target project' do
      expect(result_message).to be_nil
    end

    context 'when project has custom commit template' do
      let(message_template_name) { <<~MSG.rstrip }
        %{title}

        See merge request %{reference}
      MSG

      it 'uses custom template' do
        expect(result_message).to eq <<~MSG.rstrip
          Bugfix

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end
    end

    context 'when project has commit template with only the title' do
      let(:merge_request) do
        double(
          :merge_request,
          title: 'Fixes',
          target_project: project,
          to_reference: '!123',
          metrics: nil,
          merge_user: nil
        )
      end

      let(message_template_name) { '%{title}' }

      it 'evaluates only necessary variables' do
        expect(result_message).to eq 'Fixes'
        expect(merge_request).not_to have_received(:to_reference)
      end
    end

    context 'when project has commit template with title and local reference' do
      let(:merge_request) do
        double(
          :merge_request,
          title: 'Fixes',
          target_project: project,
          to_reference: '!123',
          metrics: nil,
          merge_user: nil
        )
      end

      let(message_template_name) { '%{title} (%{local_reference})' }

      it 'evaluates only necessary variables' do
        expect(result_message).to eq 'Fixes (!123)'
      end
    end

    context 'when project has commit template with source project id' do
      let(:merge_request) do
        double(
          :merge_request,
          title: 'Fixes',
          target_project: project,
          source_project: project,
          to_reference: '!123',
          metrics: nil,
          merge_user: nil
        )
      end

      let(message_template_name) { '%{source_project_id}' }

      it 'evaluates only necessary variables' do
        expect(result_message).to eq project.id.to_s
      end
    end

    context 'when project has commit template with closed issues' do
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{title}

        %{issues}

        See merge request %{reference}
      MSG

      it 'omits issues and new lines when no issues are mentioned in description' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Bugfix

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when MR closes issues' do
        let(:issue_1) { create(:issue, project: project) }
        let(:issue_2) { create(:issue, project: project) }
        let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

        it 'includes them and keeps new line characters' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            Closes #{issue_1.to_reference} and #{issue_2.to_reference}

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end

    context 'when project has commit template with description' do
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{title}

        %{description}

        See merge request %{reference}
      MSG

      it 'uses template' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Bugfix

          Merge Request Description
          Next line

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when description is empty string' do
        let(:merge_request_description) { '' }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end

      context 'when description is nil' do
        let(:merge_request_description) { nil }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end

      context 'when description is blank string' do
        let(:merge_request_description) { "\n\r  \n" }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end

    context 'when custom commit template contains placeholder in the middle or beginning of the line' do
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{description} %{title}

        See merge request %{reference}
      MSG

      it 'uses custom template' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Merge Request Description
          Next line Bugfix

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when description is empty string' do
        let(:merge_request_description) { '' }

        it 'does not remove new line characters before empty placeholder' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

             Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end
    end

    context 'when project has template with CRLF newlines' do
      let(message_template_name) do
        "Merge branch '%{source_branch}' into '%{target_branch}'\r\n\r\n%{title}\r\n\r\n%{description}\r\n\r\nSee merge request %{reference}"
      end

      it 'converts it to LF newlines' do
        expect(result_message).to eq <<~MSG.rstrip
          Merge branch 'feature' into 'master'

          Bugfix

          Merge Request Description
          Next line

          See merge request #{merge_request.to_reference(full: true)}
        MSG
      end

      context 'when description is empty string' do
        let(:merge_request_description) { '' }

        it 'skips description placeholder and removes new line characters before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Bugfix

            See merge request #{merge_request.to_reference(full: true)}
          MSG
        end
      end

      context 'when project has merge commit template with first_commit' do
        let(message_template_name) { <<~MSG.rstrip }
          Message: %{first_commit}
        MSG

        it 'uses first commit' do
          expect(result_message).to eq <<~MSG.rstrip
            Message: Feature added

            Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          MSG
        end

        context 'when branch has no unmerged commits' do
          let(:source_branch) { 'v1.1.0' }

          it 'is an empty string' do
            expect(result_message).to eq 'Message: '
          end
        end
      end

      context 'when project has merge commit template with first_multiline_commit' do
        let(message_template_name) { <<~MSG.rstrip }
          Message: %{first_multiline_commit}
        MSG

        it 'uses first multiline commit' do
          expect(result_message).to eq <<~MSG.rstrip
            Message: Feature added

            Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          MSG
        end

        context 'when branch has no multiline commits' do
          let(:source_branch) { 'spooky-stuff' }

          it 'is mr title' do
            expect(result_message).to eq 'Message: Bugfix'
          end
        end
      end
    end

    context 'when project has merge commit template with reviewers' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{reviewed_by}
      MSG

      context 'and mr has no reviewers' do
        before do
          merge_request.reviews = []
        end

        it 'removes variable and blank line' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'
          MSG
        end

        context 'when there is blank line after reviewed_by' do
          let(message_template_name) { <<~MSG.rstrip }
            Merge branch '%{source_branch}' into '%{target_branch}'

            %{reviewed_by}

            Type: merge
          MSG

          it 'removes blank line before it' do
            expect(result_message).to eq <<~MSG.rstrip
              Merge branch 'feature' into 'master'

              Type: merge
            MSG
          end
        end

        context 'when there is no blank line after reviewed_by' do
          let(message_template_name) { <<~MSG.rstrip }
            Merge branch '%{source_branch}' into '%{target_branch}'

            %{reviewed_by}
            Type: merge
          MSG

          it 'does not remove blank line before it' do
            expect(result_message).to eq <<~MSG.rstrip
              Merge branch 'feature' into 'master'

              Type: merge
            MSG
          end
        end
      end

      context 'and mr has one reviewer' do
        before do
          merge_request.reviews.create!(project: merge_request.project, author: user1)
        end

        it 'returns user name and email' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Reviewed-by: #{user1.name} <#{user1.email}>
          MSG
        end
      end

      context 'and mr has multiple reviewers' do
        before do
          merge_request.reviews.create!(project: merge_request.project, author: user1)
          merge_request.reviews.create!(project: merge_request.project, author: user2)
        end

        it 'returns users names and emails' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Reviewed-by: #{user1.name} <#{user1.email}>
            Reviewed-by: #{user2.name} <#{user2.email}>
          MSG
        end
      end
    end

    context 'when project has merge commit template with approvers' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(message_template_name) { <<~MSG.rstrip }
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{approved_by}
      MSG

      context 'and mr has no approval' do
        before do
          merge_request.approved_by_users = []
        end

        it 'removes variable and blank line' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'
          MSG
        end

        context 'when there is blank line after approved_by' do
          let(message_template_name) { <<~MSG.rstrip }
            Merge branch '%{source_branch}' into '%{target_branch}'

            %{approved_by}

            Type: merge
          MSG

          it 'removes blank line before it' do
            expect(result_message).to eq <<~MSG.rstrip
              Merge branch 'feature' into 'master'

              Type: merge
            MSG
          end
        end

        context 'when there is no blank line after approved_by' do
          let(message_template_name) { <<~MSG.rstrip }
            Merge branch '%{source_branch}' into '%{target_branch}'

            %{approved_by}
            Type: merge
          MSG

          it 'does not remove blank line before it' do
            expect(result_message).to eq <<~MSG.rstrip
              Merge branch 'feature' into 'master'

              Type: merge
            MSG
          end
        end
      end

      context 'and mr has one approval' do
        before do
          merge_request.approved_by_users = [user1]
        end

        it 'returns user name and email' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Approved-by: #{user1.name} <#{user1.email}>
          MSG
        end
      end

      context 'and mr has multiple approvals' do
        before do
          merge_request.approved_by_users = [user1, user2]
        end

        it 'returns users names and emails' do
          expect(result_message).to eq <<~MSG.rstrip
            Merge branch 'feature' into 'master'

            Approved-by: #{user1.name} <#{user1.email}>
            Approved-by: #{user2.name} <#{user2.email}>
          MSG
        end
      end
    end

    context 'when project has merge commit template with url' do
      let(message_template_name) do
        "Merge Request URL is '%{url}'"
      end

      context "and merge request has url" do
        it "returns mr url" do
          expect(result_message).to eq <<~MSG.rstrip
          Merge Request URL is '#{Gitlab::UrlBuilder.build(merge_request)}'
          MSG
        end
      end
    end

    context 'when project has merge commit template with merged_by' do
      let(message_template_name) do
        "Merge Request merged by '%{merged_by}'"
      end

      context "and current_user is passed" do
        it "returns user name and email" do
          expect(result_message).to eq <<~MSG.rstrip
          Merge Request merged by '#{current_user.name} <#{current_user.email}>'
          MSG
        end
      end
    end

    context 'when project has commit template with all_commits' do
      let(message_template_name) { "All commits:\n%{all_commits}" }

      it 'returns all commit messages' do
        expect(result_message).to eq <<~MSG.rstrip
          All commits:
          * Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
        MSG
      end

      context 'with 2 commits' do
        let(:source_branch) { 'fix' }

        it 'returns both messages' do
          expect(result_message).to eq <<~MSG.rstrip
            All commits:
            * Test file for directories with a leading dot

            * JS fix

            Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          MSG
        end
      end

      context 'with over 100 commits' do
        let(:source_branch) { 'signed-commits' }

        it 'returns first 100 commits skipping merge commit' do
          expected_message = <<~MSG
            All commits:
            * Multiple signatures commit

            * Add conflicting file

            * Add conflicting file

          MSG
          expected_message += (5..100).to_a.reverse
                                .map { |n| "* Unrelated signed commit #{n} to exceed page size of endpoint\n\n" }
                                .join.rstrip
          expect(result_message).to eq expected_message
        end
      end

      context 'when branch has no unmerged commits' do
        let(:source_branch) { 'v1.1.0' }

        it 'is an empty string' do
          expect(result_message).to eq "All commits:\n"
        end
      end

      context 'when branch has commit with message over 100kb' do
        let(:source_branch) { 'add_commit_with_5mb_subject' }

        it 'skips commit body' do
          expect(result_message).to eq <<~MSG.rstrip
            All commits:
            * Commit with 5MB text subject

            -- Skipped commit body exceeding 100KiB in size.

            * Correct test_env.rb path for adding branch

            * Add file with a _flattable_ path


            (cherry picked from commit ce369011c189f62c815f5971d096b26759bab0d1)

            * Add file larger than 1 mb

            In order to test Max File Size push rule we need a file larger than 1 MB

            * LFS tracks "*.lfs" through .gitattributes

            * Update README.md to include `Usage in testing and development`
          MSG
        end
      end
    end

    context 'user' do
      subject { described_class.new(merge_request: merge_request, current_user: nil) }

      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(message_template_name) do
        "Merge Request merged by '%{merged_by}'"
      end

      context 'comes from metrics' do
        before do
          merge_request.metrics.merged_by = user1
        end

        it "returns user name and email" do
          expect(result_message).to eq <<~MSG.rstrip
          Merge Request merged by '#{user1.name} <#{user1.email}>'
          MSG
        end
      end

      context 'comes from merge_user' do
        before do
          merge_request.merge_user = user2
        end

        it "returns user name and email" do
          expect(result_message).to eq <<~MSG.rstrip
          Merge Request merged by '#{user2.name} <#{user2.email}>'
          MSG
        end
      end
    end

    context 'when project has commit template with the same variable used twice' do
      let(message_template_name) { '%{title} %{title}' }

      it 'uses custom template' do
        expect(result_message).to eq 'Bugfix Bugfix'
      end
    end

    context 'when project has commit template without any variable' do
      let(message_template_name) { 'static text' }

      it 'uses custom template' do
        expect(result_message).to eq 'static text'
      end
    end

    context 'when project has template with all variables' do
      let(message_template_name) { <<~MSG.rstrip }
        source_branch:%{source_branch}
        target_branch:%{target_branch}
        title:%{title}
        issues:%{issues}
        description:%{description}
        first_commit:%{first_commit}
        first_multiline_commit:%{first_multiline_commit}
        url:%{url}
        reviewed_by:%{reviewed_by}
        approved_by:%{approved_by}
        merged_by:%{merged_by}
        co_authored_by:%{co_authored_by}
        merge_request_author:%{merge_request_author}
        all_commits:%{all_commits}
      MSG

      it 'uses custom template' do
        expect(result_message).to eq <<~MSG.rstrip
          source_branch:feature
          target_branch:master
          title:Bugfix
          issues:
          description:Merge Request Description
          Next line
          first_commit:Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          first_multiline_commit:Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          url:#{Gitlab::UrlBuilder.build(merge_request)}
          reviewed_by:
          approved_by:
          merged_by:#{current_user.name} <#{current_user.commit_email_or_default}>
          co_authored_by:Co-authored-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          merge_request_author:John Doe <john.doe@example.com>
          all_commits:* Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
        MSG
      end
    end

    context 'when project has merge commit template with co_authored_by' do
      let(:source_branch) { 'signed-commits' }
      let(message_template_name) { <<~MSG.rstrip }
        %{title}

        %{co_authored_by}
      MSG

      it 'uses custom template' do
        expect(result_message).to eq <<~MSG.rstrip
          Bugfix

          Co-authored-by: Nannie Bernhard <nannie.bernhard@example.com>
          Co-authored-by: Winnie Hellmann <winnie@gitlab.com>
        MSG
      end

      context 'when author and merging user is one of the commit authors' do
        let(:author) { create(:user, email: 'nannie.bernhard@example.com') }

        before do
          merge_request.merge_user = author
        end

        it 'skips his mail in coauthors' do
          expect(result_message).to eq <<~MSG.rstrip
            Bugfix

            Co-authored-by: Winnie Hellmann <winnie@gitlab.com>
          MSG
        end
      end

      context 'when author and merging user is the only author of commits' do
        let(:author) { create(:user, email: 'dmitriy.zaporozhets@gmail.com') }
        let(:source_branch) { 'feature' }

        before do
          merge_request.merge_user = author
        end

        it 'skips coauthors and empty lines before it' do
          expect(result_message).to eq <<~MSG.rstrip
            Bugfix
          MSG
        end
      end
    end
  end

  describe '#merge_commit_message' do
    let(:result_message) { subject.merge_commit_message }

    it_behaves_like 'commit message with template', :merge_commit_template

    context 'when project has merge commit template with co_authored_by' do
      let(:source_branch) { 'signed-commits' }
      let(:merge_commit_template) { <<~MSG.rstrip }
        %{title}

        %{co_authored_by}
      MSG

      context 'when author and merging user are one of the commit authors' do
        let(:author) { create(:user, email: 'nannie.bernhard@example.com') }
        let(:merge_user) { create(:user, email: 'winnie@gitlab.com') }

        before do
          merge_request.merge_user = merge_user
        end

        it 'skips merging user, but does not skip merge request author' do
          expect(result_message).to eq <<~MSG.rstrip
            Bugfix

            Co-authored-by: Nannie Bernhard <nannie.bernhard@example.com>
          MSG
        end
      end
    end

    context 'when project has merge commit template with merge_request_author' do
      let(:source_branch) { 'signed-commits' }
      let(:merge_commit_template) { <<~MSG.rstrip }
        %{title}

        %{merge_request_author}
      MSG

      context 'when author is one of the commit authors' do
        let(:author) { create(:user, name: 'Nannie Bernhard', email: 'nannie.bernhard@example.com') }

        it 'uses the merge request author' do
          expect(result_message).to eq <<~MSG.rstrip
            Bugfix

            Nannie Bernhard <nannie.bernhard@example.com>
          MSG
        end
      end
    end
  end

  describe '#squash_commit_message' do
    let(:result_message) { subject.squash_commit_message }

    it_behaves_like 'commit message with template', :squash_commit_template

    context 'when project has merge commit template with co_authored_by' do
      let(:source_branch) { 'signed-commits' }
      let(:squash_commit_template) { <<~MSG.rstrip }
        %{title}

        %{co_authored_by}
      MSG

      context 'when author and merging user are one of the commit authors' do
        let(:author) { create(:user, email: 'nannie.bernhard@example.com') }
        let(:merge_user) { create(:user, email: 'winnie@gitlab.com') }

        before do
          merge_request.merge_user = merge_user
        end

        it 'skips merge request author, but does not skip merging user' do
          expect(result_message).to eq <<~MSG.rstrip
            Bugfix

            Co-authored-by: Winnie Hellmann <winnie@gitlab.com>
          MSG
        end
      end
    end

    context 'when project has merge commit template with merge_request_author' do
      let(:author) { create(:user, name: 'Nannie Bernhard', email: 'nannie.bernhard@example.com') }
      let(:squash_commit_template) { <<~MSG.rstrip }
        %{title}

        %{merge_request_author}
      MSG

      it 'uses the merge request author' do
        expect(result_message).to eq <<~MSG.rstrip
          Bugfix

          Nannie Bernhard <nannie.bernhard@example.com>
        MSG
      end
    end
  end

  describe '#new_mr_description' do
    let(:merge_request) do
      build(
        :merge_request,
        source_project: project,
        target_project: project,
        target_branch: 'master',
        source_branch: source_branch,
        author: author,
        description: merge_request_description,
        title: merge_request_title
      )
    end

    let(:result_message) { subject.new_mr_description }

    before do
      compare = CompareService.new(
        project,
        merge_request.source_branch
      ).execute(
        project,
        merge_request.target_branch
      )

      merge_request.compare_commits = compare.commits
      merge_request.compare = compare
    end

    context 'when project has template with all variables' do
      let(:merge_request_description) { <<~MSG.rstrip }
        source_branch:%{source_branch}
        target_branch:%{target_branch}
        title:%{title}
        issues:%{issues}
        description:%{description}
        first_commit:%{first_commit}
        first_multiline_commit:%{first_multiline_commit}
        url:%{url}
        approved_by:%{approved_by}
        merged_by:%{merged_by}
        co_authored_by:%{co_authored_by}
        merge_request_author:%{merge_request_author}
        all_commits:%{all_commits}
      MSG

      it 'renders only variables specific to a new non-persisted merge request' do
        expect(result_message).to eq <<~MSG.rstrip
          source_branch:feature
          target_branch:master
          title:
          issues:
          description:
          first_commit:Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          first_multiline_commit:Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          url:
          approved_by:
          merged_by:
          co_authored_by:Co-authored-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
          merge_request_author:
          all_commits:* Feature added

          Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
        MSG
      end

      context 'when no first commit exists' do
        let(:source_branch) { 'master' }

        it 'does not populate any commit-related variables' do
          expect(result_message).to eq <<~MSG.rstrip
            source_branch:master
            target_branch:master
            title:
            issues:
            description:
            first_commit:
            first_multiline_commit:Bugfix
            url:
            approved_by:
            merged_by:
            co_authored_by:
            merge_request_author:
            all_commits:
          MSG
        end
      end
    end
  end
end
