# frozen_string_literal: true
require 'spec_helper'

RSpec.describe MergeRequests::BuildService, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax
  include RepoHelpers
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:source_project) { nil }
  let(:target_project) { nil }
  let(:user) { create(:user, name: "John Doe", email: "jdoe@gitlab.com") }
  let(:issue_confidential) { false }
  let(:issue) { create(:issue, project: project, title: 'A bug', confidential: issue_confidential) }
  let(:description) { nil }
  let(:source_branch) { 'feature' }
  let(:target_branch) { 'master' }
  let(:milestone_id) { nil }
  let(:label_ids) { [] }
  let(:merge_request) { service.execute }
  let(:compare) { double(:compare, commits: commits) }
  let(:commit_1) do
    double(:commit_1,
      sha: 'f00ba6',
      safe_message: 'Initial commit',
      gitaly_commit?: false,
      id: 'f00ba6',
      parent_ids: ['f00ba5'],
      author_email: 'tom@example.com',
      author_name: 'Tom Example')
  end

  let(:commit_2) do
    double(:commit_2,
      sha: 'f00ba7',
      safe_message: "Closes #1234 Second commit\n\nCreate the app",
      gitaly_commit?: false,
      id: 'f00ba7',
      parent_ids: ['f00ba6'],
      author_email: 'alice@example.com',
      author_name: 'Alice Example')
  end

  let(:commit_3) do
    double(:commit_3,
      sha: 'f00ba8',
      safe_message: 'This is a bad commit message!',
      gitaly_commit?: false,
      id: 'f00ba8',
      parent_ids: ['f00ba7'],
      author_email: 'jo@example.com',
      author_name: 'Jo Example')
  end

  let(:commits) { nil }

  let(:params) do
    {
      description: description,
      source_branch: source_branch,
      target_branch: target_branch,
      source_project: source_project,
      target_project: target_project,
      milestone_id: milestone_id,
      label_ids: label_ids
    }
  end

  let(:service) do
    described_class.new(project: project, current_user: user, params: params)
  end

  before do
    project.repository.create_branch(source_branch, target_branch) if source_branch && target_branch

    project.add_guest(user)
  end

  def stub_compare
    allow(CompareService).to receive_message_chain(:new, :execute).and_return(compare)
    allow(project).to receive(:commit).and_return(commit_1)
    allow(project).to receive(:commit).and_return(commit_2)
    allow(project).to receive(:commit).and_return(commit_3)
  end

  shared_examples 'allows the merge request to be created' do
    it do
      expect(merge_request.can_be_created).to eq(true)
    end
  end

  shared_examples 'forbids the merge request from being created' do
    it 'returns that the merge request cannot be created' do
      expect(merge_request.can_be_created).to eq(false)
    end

    it 'adds an error message to the merge request' do
      expect(merge_request.errors).to contain_exactly(*Array(error_message))
    end
  end

  shared_examples 'with a Default.md template' do
    let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
    let(:project) { create(:project, :custom_repo, files: files) }

    it 'the template description is preferred' do
      expect(merge_request.description).to eq('Default template contents')
    end
  end

  describe '#execute' do
    it 'calls the compare service with the correct arguments' do
      allow_any_instance_of(described_class).to receive(:projects_and_branches_valid?).and_return(true)
      expect(CompareService).to receive(:new)
                                  .with(project, Gitlab::Git::BRANCH_REF_PREFIX + source_branch)
                                  .and_call_original

      expect_any_instance_of(CompareService).to receive(:execute)
                                                  .with(project, Gitlab::Git::BRANCH_REF_PREFIX + target_branch)
                                                  .and_call_original

      merge_request
    end

    it 'does not assign force_remove_source_branch' do
      expect(merge_request.force_remove_source_branch?).to be_truthy
    end

    context 'with force_remove_source_branch parameter when the user is authorized' do
      let(:mr_params) { params.merge(force_remove_source_branch: '1') }
      let(:source_project) { fork_project(project, user) }
      let(:merge_request) { described_class.new(project: project, current_user: user, params: mr_params).execute }

      before do
        project.add_reporter(user)
      end

      it 'assigns force_remove_source_branch' do
        expect(merge_request.force_remove_source_branch?).to be_truthy
      end

      context 'with project setting remove_source_branch_after_merge false' do
        before do
          project.remove_source_branch_after_merge = false
        end

        it 'assigns force_remove_source_branch' do
          expect(merge_request.force_remove_source_branch?).to be_truthy
        end
      end
    end

    context 'with project setting remove_source_branch_after_merge true' do
      before do
        project.remove_source_branch_after_merge = true
      end

      it 'assigns force_remove_source_branch' do
        expect(merge_request.force_remove_source_branch?).to be_truthy
      end

      context 'with force_remove_source_branch parameter false' do
        before do
          params[:force_remove_source_branch] = '0'
        end

        it 'does not assign force_remove_source_branch' do
          expect(merge_request.force_remove_source_branch?).to be(false)
        end
      end
    end

    context 'missing source branch' do
      let(:source_branch) { nil }

      it_behaves_like 'forbids the merge request from being created' do
        let(:error_message) { 'You must select source and target branch' }
      end
    end

    context 'when target branch is missing' do
      let(:target_branch) { nil }
      let(:commits) { Commit.decorate([commit_2], project) }

      before do
        stub_compare
      end

      context 'when source branch' do
        context 'is not the repository default branch' do
          it 'creates compare object with target branch as default branch' do
            expect(merge_request.compare).to be_present
            expect(merge_request.target_branch).to eq(project.default_branch)
          end

          it_behaves_like 'allows the merge request to be created'
        end

        context 'the repository default branch' do
          let(:source_branch) { 'master' }

          it_behaves_like 'forbids the merge request from being created' do
            let(:error_message) { 'You must select source and target branch' }
          end

          context 'when source project is different from the target project' do
            let(:target_project) { create(:project, :public, :repository) }
            let!(:project) { fork_project(target_project, user, namespace: user.namespace, repository: true) }
            let(:source_project) { project }

            it 'creates compare object with target branch as default branch', :sidekiq_might_not_need_inline do
              expect(merge_request.compare).to be_present
              expect(merge_request.target_branch).to eq(project.default_branch)
            end

            it_behaves_like 'allows the merge request to be created'
          end
        end
      end
    end

    context 'same source and target branch' do
      let(:source_branch) { 'master' }

      it_behaves_like 'forbids the merge request from being created' do
        let(:error_message) { 'You must select different branches' }
      end
    end

    context 'no commits in the diff' do
      let(:commits) { [] }

      before do
        stub_compare
      end

      it_behaves_like 'allows the merge request to be created'

      it 'adds a Draft prefix to the merge request title' do
        expect(merge_request.title).to eq('Draft: Feature')
      end
    end

    context 'one commit in the diff' do
      let(:commits) { Commit.decorate([commit_2], project) }
      let(:commit_description) { commit_2.safe_message.split(/\n+/, 2).last }

      before do
        stub_compare

        project.add_developer(user)
      end

      it_behaves_like 'allows the merge request to be created'
      it_behaves_like 'with a Default.md template'

      it 'uses the title of the commit as the title of the merge request' do
        expect(merge_request.title).to eq(commit_2.safe_message.split("\n").first)
      end

      it 'uses the description of the commit as the description of the merge request' do
        expect(merge_request.description).to eq(commit_description)
      end

      context 'merge request already has a description set' do
        let(:description) { 'Merge request description' }

        it 'keeps the description from the initial params' do
          expect(merge_request.description).to eq(description)
        end
      end

      context 'commit has no description' do
        let(:commits) { Commit.decorate([commit_3], project) }

        it_behaves_like 'with a Default.md template'

        it 'uses the title of the commit as the title of the merge request' do
          expect(merge_request.title).to eq(commit_3.safe_message)
        end

        it 'sets the description to nil' do
          expect(merge_request.description).to be_nil
        end
      end

      context 'when the source branch matches an issue' do
        where(:factory, :source_branch, :closing_message) do
          :jira_integration | 'FOO-123-fix-issue' | 'Closes FOO-123'
          :jira_integration | 'fix-issue'         | nil
          :custom_issue_tracker_integration | '123-fix-issue'     | 'Closes #123'
          :custom_issue_tracker_integration | 'fix-issue'         | nil
          nil | '123-fix-issue'     | 'Closes #123'
          nil | 'fix-issue'         | nil
        end

        with_them do
          before do
            if factory
              create(factory, project: project)
              project.reload
            else
              issue.update!(iid: 123)
            end
          end

          it 'uses the title of the commit as the title of the merge request' do
            expect(merge_request.title).to eq('Closes #1234 Second commit')
          end

          it 'appends the closing description' do
            expected_description = [commit_description, closing_message].compact.join("\n\n")

            expect(merge_request.description).to eq(expected_description)
          end

          context 'a Default.md template is defined' do
            let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
            let(:project) { create(:project, :custom_repo, files: files) }

            it 'appends the closing description to a Default.md template' do
              expected_description = ['Default template contents', closing_message].compact.join("\n\n")

              expect(merge_request.description).to eq(expected_description)
            end
          end
        end

        context 'when the source branch matches an internal issue' do
          let(:label) { create(:label, project: project) }
          let(:milestone) { create(:milestone, project: project) }
          let(:source_branch) { '123-fix-issue' }

          before do
            issue.update!(iid: 123, labels: [label], milestone: milestone)
          end

          it 'assigns the issue label and milestone' do
            expect(merge_request.milestone).to eq(milestone)
            expect(merge_request.labels).to match_array([label])
          end

          context 'when milestone_id and label_ids are shared in the params' do
            let(:label2) { create(:label, project: project) }
            let(:milestone2) { create(:milestone, project: project) }
            let(:label_ids) { [label2.id] }
            let(:milestone_id) { milestone2.id }

            before do
              # Guests are not able to assign labels or milestones to an issue
              project.add_developer(user)
            end

            it 'assigns milestone_id and label_ids instead of issue labels and milestone' do
              expect(merge_request.milestone).to eq(milestone2)
              expect(merge_request.labels).to match_array([label2])
            end
          end
        end

        context 'when a milestone is from another project' do
          let(:milestone) { create(:milestone, project: create(:project)) }
          let(:milestone_id) { milestone.id }

          it 'sets milestone to nil' do
            expect(merge_request.milestone).to be_nil
          end
        end
      end
    end

    context 'no multi-line commit messages in the diff' do
      let(:commits) { Commit.decorate([commit_1, commit_3], project) }

      before do
        stub_compare

        project.add_developer(user)
      end

      it_behaves_like 'allows the merge request to be created'
      it_behaves_like 'with a Default.md template'

      it 'uses the title of the branch as the merge request title' do
        expect(merge_request.title).to eq('Feature')
      end

      it 'does not add a description' do
        expect(merge_request.description).to be_nil
      end

      context 'merge request already has a description set' do
        let(:description) { 'Merge request description' }

        it 'keeps the description from the initial params' do
          expect(merge_request.description).to eq(description)
        end

        context 'a Default.md template is defined' do
          let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
          let(:project) { create(:project, :custom_repo, files: files) }

          it 'keeps the description from the initial params' do
            expect(merge_request.description).to eq(description)
          end
        end
      end

      context 'when the source branch matches an issue' do
        where(:factory, :source_branch, :title, :closing_message) do
          :jira_integration | 'FOO-123-fix-issue' | 'Resolve FOO-123 "Fix issue"' | 'Closes FOO-123'
          :jira_integration | 'fix-issue'         | 'Fix issue'                   | nil
          :custom_issue_tracker_integration | '123-fix-issue'     | 'Resolve #123 "Fix issue"'    | 'Closes #123'
          :custom_issue_tracker_integration | 'fix-issue'         | 'Fix issue'                   | nil
          nil | '123-fix-issue'     | 'Resolve "A bug"'             | 'Closes #123'
          nil | 'fix-issue'         | 'Fix issue'                   | nil
          nil | '124-fix-issue'     | '124 fix issue'               | nil
        end

        with_them do
          before do
            if factory
              create(factory, project: project)
              project.reload
            else
              issue.update!(iid: 123)
            end
          end

          it 'sets the correct title' do
            expect(merge_request.title).to eq(title)
          end

          it 'sets the closing description' do
            expect(merge_request.description).to eq(closing_message)
          end

          context 'a Default.md template is defined' do
            let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
            let(:project) { create(:project, :custom_repo, files: files) }

            it 'appends the closing description to a Default.md template' do
              expected_description = ['Default template contents', closing_message].compact.join("\n\n")

              expect(merge_request.description).to eq(expected_description)
            end
          end
        end
      end
    end

    context 'a multi-line commit message in the diff' do
      let(:commits) { Commit.decorate([commit_1, commit_2, commit_3], project) }

      before do
        stub_compare
      end

      it_behaves_like 'allows the merge request to be created'
      it_behaves_like 'with a Default.md template'

      it 'uses the first line of the first multi-line commit message as the title' do
        expect(merge_request.title).to eq('Closes #1234 Second commit')
      end

      it 'adds the remaining lines of the first multi-line commit message as the description' do
        expect(merge_request.description).to eq('Create the app')
      end

      context 'when the source branch matches an issue' do
        where(:factory, :source_branch, :title, :closing_message) do
          :jira_integration | 'FOO-123-fix-issue' | 'Resolve FOO-123 "Fix issue"' | 'Closes FOO-123'
          :jira_integration | 'fix-issue'         | 'Fix issue'                   | nil
          :custom_issue_tracker_integration | '123-fix-issue'     | 'Resolve #123 "Fix issue"'    | 'Closes #123'
          :custom_issue_tracker_integration | 'fix-issue'         | 'Fix issue'                   | nil
          nil | '123-fix-issue'     | 'Resolve "A bug"'             | 'Closes #123'
          nil | 'fix-issue'         | 'Fix issue'                   | nil
          nil | '124-fix-issue'     | '124 fix issue'               | nil
        end

        with_them do
          before do
            if factory
              create(factory, project: project)
              project.reload
            else
              issue.update!(iid: 123)
            end
          end

          it 'sets the correct title' do
            expect(merge_request.title).to eq('Closes #1234 Second commit')
          end

          it 'sets the closing description' do
            expect(merge_request.description).to eq("Create the app#{closing_message ? "\n\n" + closing_message : ''}")
          end

          context 'a Default.md template is defined' do
            let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
            let(:project) { create(:project, :custom_repo, files: files) }

            it 'appends the closing description to a Default.md template' do
              expected_description = ['Default template contents', closing_message].compact.join("\n\n")

              expect(merge_request.description).to eq(expected_description)
            end
          end
        end
      end

      context 'when the issue is not accessible to user' do
        let(:source_branch) { "#{issue.iid}-fix-issue" }

        before do
          project.team.truncate
        end

        it 'uses the first line of the first multi-line commit message as the title' do
          expect(merge_request.title).to eq('Closes #1234 Second commit')
        end

        it 'adds the remaining lines of the first multi-line commit message as the description', :sidekiq_inline do
          expect(merge_request.description).to eq('Create the app')
        end
      end

      context 'when the issue is confidential' do
        let(:source_branch) { "#{issue.iid}-fix-issue" }
        let(:issue_confidential) { true }

        it 'uses the first line of the first multi-line commit message as the title' do
          expect(merge_request.title).to eq('Closes #1234 Second commit')
        end

        it 'adds the remaining lines of the first multi-line commit message as the description' do
          expect(merge_request.description).to eq('Create the app')
        end
      end
    end

    context 'source branch does not exist' do
      before do
        allow(project).to receive(:branch_exists?).with(target_branch).and_return(true)
        allow(project).to receive(:branch_exists?).with(source_branch).and_return(false)
      end

      it_behaves_like 'forbids the merge request from being created' do
        let(:error_message) { 'Source branch "feature" does not exist' }
      end
    end

    context 'target branch does not exist' do
      before do
        allow(project).to receive(:branch_exists?).with(target_branch).and_return(false)
        allow(project).to receive(:branch_exists?).with(source_branch).and_return(true)
      end

      it_behaves_like 'forbids the merge request from being created' do
        let(:error_message) { 'Target branch "master" does not exist' }
      end
    end

    context 'both source and target branches do not exist' do
      before do
        allow(project).to receive(:branch_exists?).and_return(false)
      end

      it_behaves_like 'forbids the merge request from being created' do
        let(:error_message) do
          ['Source branch "feature" does not exist', 'Target branch "master" does not exist']
        end
      end
    end

    context 'upstream project has disabled merge requests' do
      let(:upstream_project) { create(:project, :merge_requests_disabled) }
      let(:project) { create(:project, :repository, forked_from_project: upstream_project) }
      let(:commits) { Commit.decorate([commit_2], project) }

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(project)
      end
    end

    context 'target_project is set and accessible by current_user' do
      let(:target_project) { create(:project, :public, :repository) }
      let(:commits) { Commit.decorate([commit_2], project) }

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(target_project)
      end
    end

    context 'target_project is set but not accessible by current_user' do
      let(:target_project) { create(:project, :private, :repository) }
      let(:commits) { Commit.decorate([commit_2], project) }

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(project)
      end
    end

    context 'target_project is set but repo is not accessible by current_user' do
      let(:target_project) do
        create(:project, :public, :repository, repository_access_level: ProjectFeature::PRIVATE)
      end

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(project)
      end
    end

    context 'source_project is set and accessible by current_user' do
      let(:source_project) { create(:project, :public, :repository) }
      let(:commits) { Commit.decorate([commit_2], project) }

      before do
        # To create merge requests _from_ a project the user needs at least
        # developer access
        source_project.add_developer(user)
      end

      it 'sets source project correctly' do
        expect(merge_request.source_project).to eq(source_project)
      end
    end

    context 'source_project is set but not accessible by current_user' do
      let(:source_project) { create(:project, :private, :repository) }
      let(:commits) { Commit.decorate([commit_2], project) }

      it 'sets source project correctly' do
        expect(merge_request.source_project).to eq(project)
      end
    end

    context 'source_project is set but the user cannot create merge requests from the project' do
      let(:source_project) do
        create(:project, :public, :repository, merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it 'sets the source_project correctly' do
        expect(merge_request.source_project).to eq(project)
      end
    end

    context 'target_project is not in the fork network of source_project' do
      let(:target_project) { create(:project, :public, :repository) }

      it 'adds an error to the merge request' do
        expect(merge_request.errors[:validate_fork]).to contain_exactly('Source project is not a fork of the target project')
      end
    end

    context 'target_project is in the fork network of source project but no longer accessible' do
      let!(:project) { fork_project(target_project, user, namespace: user.namespace, repository: true) }
      let(:source_project) { project }
      let(:target_project) { create(:project, :public, :repository) }

      before do
        target_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'sets the target_project correctly' do
        expect(merge_request.target_project).to eq(project)
      end
    end

    context 'when specifying target branch in the description' do
      let(:description) { "A merge request targeting another branch\n\n/target_branch with-codeowners" }

      it 'sets the attribute from the quick actions' do
        expect(merge_request.target_branch).to eq('with-codeowners')
      end
    end
  end

  context 'when assigning labels' do
    let(:label_ids) { [create(:label, project: project).id] }

    context 'for members with less than developer access' do
      it 'is not allowed' do
        expect(merge_request.label_ids).to be_empty
      end
    end

    context 'for users allowed to assign labels' do
      before do
        project.add_developer(user)
      end

      context 'for labels in the project' do
        it 'is allowed for developers' do
          expect(merge_request.label_ids).to contain_exactly(*label_ids)
        end
      end

      context 'for unrelated labels' do
        let(:project_label) { create(:label, project: project) }
        let(:label_ids) { [create(:label).id, project_label.id] }

        it 'only assigns related labels' do
          expect(merge_request.label_ids).to contain_exactly(project_label.id)
        end
      end
    end
  end

  describe '#assign_description_from_repository_template' do
    subject { service.send(:assign_description_from_repository_template) }

    it 'performs no action if the merge request description is not blank' do
      merge_request.description = 'foo'
      subject
      expect(merge_request.description).to eq 'foo'
    end

    context 'when a Default template is not found' do
      it 'does not modify the merge request description' do
        merge_request.description = nil
        subject
        expect(merge_request.description).to be_nil
      end
    end

    context 'when a Default template is found' do
      context 'when its contents cannot be retrieved' do
        let(:files) { { '.gitlab/merge_request_templates/OtherTemplate.md' => 'Other template contents' } }
        let(:project) { create(:project, :custom_repo, files: files) }

        it 'does not modify the merge request description' do
          allow(TemplateFinder).to receive(:all_template_names).and_return({
            merge_requests: [
              { name: 'Default', id: 'default', key: 'default', project_id: project.id }
            ]
          })

          merge_request.description = nil
          subject
          expect(merge_request.description).to be_nil
        end
      end

      context 'when its contents can be retrieved' do
        let(:files) { { '.gitlab/merge_request_templates/Default.md' => 'Default template contents' } }
        let(:project) { create(:project, :custom_repo, files: files) }

        it 'modifies the merge request description' do
          merge_request.description = nil
          subject
          expect(merge_request.description).to eq 'Default template contents'
        end
      end
    end
  end

  describe '#replace_variables_in_description' do
    before do
      project.add_developer(user)
    end

    context 'when the merge request description is blank' do
      let(:description) { nil }

      it 'does not update the description' do
        expect(merge_request.description).to eq(nil)
      end
    end

    context 'when the merge request description contains template variables' do
      let(:description) { <<~MSG.rstrip }
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

      context 'when there are multiple commits in the diff' do
        let(:commits) { Commit.decorate([commit_1, commit_2, commit_3], project) }

        before do
          stub_compare
        end

        it 'replaces the variables in the description' do
          expect(merge_request.description).to eq <<~MSG.rstrip
            source_branch:feature
            target_branch:master
            title:
            issues:
            description:
            first_commit:Initial commit
            first_multiline_commit:Closes #1234 Second commit

            Create the app
            url:
            approved_by:
            merged_by:
            co_authored_by:Co-authored-by: Jo Example <jo@example.com>
            Co-authored-by: Alice Example <alice@example.com>
            Co-authored-by: Tom Example <tom@example.com>
            merge_request_author:
            all_commits:* This is a bad commit message!

            * Closes #1234 Second commit

            Create the app

            * Initial commit
          MSG
        end
      end

      context 'when there are no commits in the diff' do
        let(:commits) { [] }

        before do
          stub_compare
        end

        it 'replaces the variables in the description' do
          expect(merge_request.description).to eq <<~MSG.rstrip
            source_branch:feature
            target_branch:master
            title:
            issues:
            description:
            first_commit:
            first_multiline_commit:
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
