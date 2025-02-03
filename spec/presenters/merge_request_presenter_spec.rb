# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPresenter do
  let_it_be(:project) { create(:project, :repository) }
  let(:resource) { create(:merge_request, source_project: project) }

  let_it_be(:user) { create(:user) }

  describe '#mergeable_discussions_state' do
    subject { described_class.new(resource).mergeable_discussions_state }

    let(:discussions_state) { double }

    before do
      allow(resource).to receive(:mergeable_discussions_state?).and_return(discussions_state)
    end

    it 'returns the mergeable_discussions_state' do
      is_expected.to eq(discussions_state)
    end
  end

  describe '#ci_status' do
    subject { described_class.new(resource).ci_status }

    context 'when no head pipeline' do
      it 'return status from Ci integration' do
        ci_integration = double(Integrations::MockCi)
        ci_status = double

        allow(resource.source_project)
          .to receive(:ci_integration)
          .and_return(ci_integration)

        allow(resource).to receive(:head_pipeline).and_return(nil)

        expect(ci_integration).to receive(:commit_status)
          .with(resource.diff_head_sha, resource.source_branch)
          .and_return(ci_status)

        is_expected.to eq(ci_status)
      end
    end

    context 'when head pipeline present' do
      let(:pipeline) { build_stubbed(:ci_pipeline) }

      before do
        allow(resource).to receive(:diff_head_pipeline).and_return(pipeline)
      end

      context 'success with warnings' do
        before do
          allow(pipeline).to receive(:success?) { true }
          allow(pipeline).to receive(:has_warnings?) { true }
        end

        it 'returns "success-with-warnings"' do
          is_expected.to eq('success-with-warnings')
        end
      end

      context 'pipeline HAS status AND its not success with warnings' do
        before do
          allow(pipeline).to receive(:success?) { false }
          allow(pipeline).to receive(:has_warnings?) { false }
        end

        it 'returns pipeline status' do
          is_expected.to eq('pending')
        end
      end

      context 'pipeline has NO status AND its not success with warnings' do
        before do
          allow(pipeline).to receive(:status) { nil }
          allow(pipeline).to receive(:success?) { false }
          allow(pipeline).to receive(:has_warnings?) { false }
        end

        it 'returns "preparing"' do
          is_expected.to eq('preparing')
        end
      end
    end
  end

  describe '#conflict_resolution_path' do
    let(:presenter) { described_class.new(resource, current_user: user) }
    let(:path) { presenter.conflict_resolution_path }

    context 'when MR cannot be resolved in UI' do
      it 'does not return conflict resolution path' do
        allow(presenter).to receive_message_chain(:conflicts, :can_be_resolved_in_ui?) { false }

        expect(path).to be_nil
      end
    end

    context 'when conflicts cannot be resolved by user' do
      it 'does not return conflict resolution path' do
        allow(presenter).to receive_message_chain(:conflicts, :can_be_resolved_in_ui?) { true }
        allow(presenter).to receive_message_chain(:conflicts, :can_be_resolved_by?).with(user) { false }

        expect(path).to be_nil
      end
    end

    context 'when able to access conflict resolution UI' do
      it 'does return conflict resolution path' do
        allow(presenter).to receive_message_chain(:conflicts, :can_be_resolved_in_ui?) { true }
        allow(presenter).to receive_message_chain(:conflicts, :can_be_resolved_by?).with(user) { true }

        expect(path)
          .to eq("/#{project.full_path}/-/merge_requests/#{resource.iid}/conflicts")
      end
    end
  end

  context 'issues links' do
    let_it_be(:project) { create(:project, :private, :repository, creator: user, namespace: user.namespace) }
    let_it_be(:issue_a) { create(:issue, project: project, iid: 1) }
    let_it_be(:issue_b) { create(:issue, project: project, iid: 3) }

    let_it_be(:resource) do
      create(
        :merge_request,
        source_project: project,
        target_project: project,
        description: "Fixes #{issue_a.to_reference} Related #{issue_b.to_reference}"
      )
    end

    before_all do
      project.add_developer(user)
    end

    before do
      allow(resource.project).to receive(:default_branch)
        .and_return(resource.target_branch)
      resource.cache_merge_request_closes_issues!
    end

    describe '#issues_sentence' do
      let(:issue_c) { create(:issue, project: project, iid: 10) }
      let(:issues) { [issue_b, issue_c, issue_a] }

      subject { described_class.new(resource, current_user: user).send(:issues_sentence, project, issues) }

      it 'orders issues numerically' do
        is_expected.to eq("##{issue_a.iid}, ##{issue_b.iid}, and ##{issue_c.iid}")
      end
    end

    describe '#closing_issues_links' do
      subject { described_class.new(resource, current_user: user).closing_issues_links }

      it 'presents closing issues links' do
        is_expected.to match("#{project.full_path}/-/issues/#{issue_a.iid}")
      end

      it 'does not present related issues links' do
        is_expected.not_to match("#{project.full_path}/-/issues/#{issue_b.iid}")
      end

      it 'appends status when closing issue is already closed' do
        issue_a.close
        is_expected.to match('(closed)')
      end
    end

    describe '#mentioned_issues_links' do
      subject do
        described_class.new(resource, current_user: user)
          .mentioned_issues_links
      end

      it 'presents related issues links' do
        is_expected.to match("#{project.full_path}/-/issues/#{issue_b.iid}")
      end

      it 'does not present closing issues links' do
        is_expected.not_to match("#{project.full_path}/-/issues/#{issue_a.iid}")
      end

      it 'appends status when mentioned issue is already closed' do
        issue_b.close
        is_expected.to match('(closed)')
      end
    end

    describe '#assign_to_closing_issues_path' do
      subject do
        described_class.new(resource, current_user: user)
          .assign_to_closing_issues_path
      end

      it { is_expected.to match("#{project.full_path}/-/merge_requests/#{resource.iid}/assign_related_issues") }
    end

    describe '#assign_to_closing_issues_count' do
      subject do
        described_class.new(resource, current_user: user)
          .assign_to_closing_issues_count
      end

      before do
        assign_issues_service = double(MergeRequests::AssignIssuesService, assignable_issues: assignable_issues)
        allow(MergeRequests::AssignIssuesService).to receive(:new)
          .and_return(assign_issues_service)
      end

      context 'single closing issue' do
        let(:issue) { create(:issue) }
        let(:assignable_issues) { [issue] }

        it 'returns correct count' do
          is_expected
            .to match(1)
        end
      end

      context 'multiple closing issues' do
        let(:issues) { build_list(:issue, 2) }
        let(:assignable_issues) { issues }

        it 'returns correct count' do
          is_expected
            .to match(2)
        end
      end

      context 'no closing issue' do
        let(:assignable_issues) { [] }

        it 'returns correct count' do
          is_expected
            .to match(0)
        end
      end
    end
  end

  describe '#cancel_auto_merge_path' do
    subject do
      described_class.new(resource, current_user: user)
        .cancel_auto_merge_path
    end

    context 'when can cancel mwps' do
      it 'returns path' do
        allow(resource).to receive(:can_cancel_auto_merge?)
          .with(user)
          .and_return(true)

        is_expected.to eq("/#{resource.project.full_path}/-/merge_requests/#{resource.iid}/cancel_auto_merge")
      end
    end

    context 'when cannot cancel mwps' do
      it 'returns nil' do
        allow(resource).to receive(:can_cancel_auto_merge?)
          .with(user)
          .and_return(false)

        is_expected.to be_nil
      end
    end
  end

  describe '#merge_path' do
    subject do
      described_class.new(resource, current_user: user).merge_path
    end

    context 'when can be merged by user' do
      it 'returns path' do
        allow(resource).to receive(:can_be_merged_by?)
          .with(user)
          .and_return(true)

        is_expected
          .to eq("/#{resource.project.full_path}/-/merge_requests/#{resource.iid}/merge")
      end
    end

    context 'when cannot be merged by user' do
      it 'returns nil' do
        allow(resource).to receive(:can_be_merged_by?)
          .with(user)
          .and_return(false)

        is_expected.to be_nil
      end
    end
  end

  describe '#create_issue_to_resolve_discussions_path' do
    subject do
      described_class.new(resource, current_user: user)
        .create_issue_to_resolve_discussions_path
    end

    context 'when can create issue and issues enabled' do
      it 'returns path' do
        allow(project).to receive(:issues_enabled?) { true }
        project.add_maintainer(user)

        is_expected
          .to eq("/#{resource.project.full_path}/-/issues/new?merge_request_id=#{resource.id}&merge_request_to_resolve_discussions_of=#{resource.iid}")
      end
    end

    context 'when cannot create issue' do
      it 'returns nil' do
        allow(project).to receive(:issues_enabled?) { true }

        is_expected.to be_nil
      end
    end

    context 'when issues disabled' do
      it 'returns nil' do
        allow(project).to receive(:issues_enabled?) { false }
        project.add_maintainer(user)

        is_expected.to be_nil
      end
    end
  end

  describe '#remove_wip_path' do
    subject do
      described_class.new(resource, current_user: user).remove_wip_path
    end

    before do
      allow(resource).to receive(:draft?).and_return(true)
    end

    context 'when merge request enabled and has permission' do
      it 'has remove_wip_path' do
        allow(project).to receive(:merge_requests_enabled?) { true }
        project.add_maintainer(user)

        is_expected
          .to eq("/#{resource.project.full_path}/-/merge_requests/#{resource.iid}/remove_wip")
      end
    end

    context 'when has no permission' do
      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#target_branch_commits_path' do
    subject do
      described_class.new(resource, current_user: user)
        .target_branch_commits_path
    end

    context 'when target branch exists' do
      it 'returns path' do
        allow(resource).to receive(:target_branch_exists?) { true }

        is_expected
          .to eq("/#{resource.target_project.full_path}/-/commits/#{resource.target_branch}")
      end
    end

    context 'when target branch does not exist' do
      it 'returns nil' do
        allow(resource).to receive(:target_branch_exists?) { false }

        is_expected.to be_nil
      end
    end
  end

  describe '#source_branch_commits_path' do
    subject do
      described_class.new(resource, current_user: user)
        .source_branch_commits_path
    end

    context 'when source branch exists' do
      it 'returns path' do
        allow(resource).to receive(:source_branch_exists?) { true }

        is_expected
          .to eq("/#{resource.source_project.full_path}/-/commits/#{resource.source_branch}")
      end
    end

    context 'when source branch does not exist' do
      it 'returns nil' do
        allow(resource).to receive(:source_branch_exists?) { false }

        is_expected.to be_nil
      end
    end
  end

  describe '#target_branch_tree_path' do
    subject do
      described_class.new(resource, current_user: user)
        .target_branch_tree_path
    end

    context 'when target branch exists' do
      it 'returns path' do
        allow(resource).to receive(:target_branch_exists?) { true }

        is_expected
          .to eq("/#{resource.target_project.full_path}/-/tree/#{resource.target_branch}")
      end
    end

    context 'when target branch does not exist' do
      it 'returns nil' do
        allow(resource).to receive(:target_branch_exists?) { false }

        is_expected.to be_nil
      end
    end
  end

  describe '#source_branch_path' do
    subject do
      described_class.new(resource, current_user: user).source_branch_path
    end

    context 'when source branch exists' do
      it 'returns path' do
        allow(resource).to receive(:source_branch_exists?) { true }

        is_expected
          .to eq("/#{resource.source_project.full_path}/-/branches/#{resource.source_branch}")
      end
    end

    context 'when source branch does not exist' do
      it 'returns nil' do
        allow(resource).to receive(:source_branch_exists?) { false }

        is_expected.to be_nil
      end
    end
  end

  describe '#target_branch_path' do
    subject do
      described_class.new(resource, current_user: user).target_branch_path
    end

    context 'when target branch exists' do
      it 'returns path' do
        allow(resource).to receive(:target_branch_exists?) { true }

        is_expected
          .to eq("/#{resource.source_project.full_path}/-/branches/#{resource.target_branch}")
      end
    end

    context 'when target branch does not exist' do
      it 'returns nil' do
        allow(resource).to receive(:target_branch_exists?) { false }

        is_expected.to be_nil
      end
    end
  end

  describe '#source_branch_link' do
    subject { presenter.source_branch_link }

    let(:presenter) { described_class.new(resource, current_user: user) }

    context 'when source branch exists' do
      it 'returns link' do
        allow(resource).to receive(:source_branch_exists?) { true }

        is_expected
          .to eq("<a class=\"ref-container gl-link\" href=\"#{presenter.source_branch_commits_path}\">#{presenter.source_branch}</a>")
      end
    end

    context 'when source branch does not exist' do
      it 'returns text' do
        allow(resource).to receive(:source_branch_exists?) { false }

        is_expected.to eq("<span class=\"ref-name\">#{presenter.source_branch}</span>")
      end
    end
  end

  describe '#target_branch_link' do
    subject { presenter.target_branch_link }

    let(:presenter) { described_class.new(resource, current_user: user) }

    context 'when target branch exists' do
      it 'returns link' do
        allow(resource).to receive(:target_branch_exists?) { true }

        is_expected
          .to eq("<a class=\"ref-container gl-link\" href=\"#{presenter.target_branch_commits_path}\">#{presenter.target_branch}</a>")
      end
    end

    context 'when target branch does not exist' do
      it 'returns text' do
        allow(resource).to receive(:target_branch_exists?) { false }

        is_expected.to eq("<span class=\"ref-name\">#{presenter.target_branch}</span>")
      end
    end
  end

  describe '#source_branch_with_namespace_link' do
    subject do
      described_class.new(resource, current_user: user).source_branch_with_namespace_link
    end

    it 'returns link' do
      allow(resource).to receive(:source_branch_exists?) { true }

      is_expected
        .to eq("<a href=\"/#{resource.source_project.full_path}/-/tree/#{resource.source_branch}\">#{resource.source_branch}</a>")
    end

    it 'escapes html, when source_branch does not exist' do
      xss_attempt = "<img src='x' onerror=alert('bad stuff') />"

      allow(resource).to receive(:source_branch) { xss_attempt }
      allow(resource).to receive(:source_branch_exists?) { false }

      is_expected.to eq(ERB::Util.html_escape(xss_attempt))
    end
  end

  describe '#rebase_path' do
    before do
      allow(resource).to receive(:rebase_in_progress?) { rebase_in_progress }
      allow(resource).to receive(:should_be_rebased?) { should_be_rebased }

      allow_any_instance_of(Gitlab::UserAccess::RequestCacheExtension)
        .to receive(:can_push_to_branch?)
        .with(resource.source_branch)
        .and_return(can_push_to_branch)
    end

    subject do
      described_class.new(resource, current_user: user).rebase_path
    end

    context 'when can rebase' do
      let(:rebase_in_progress) { false }
      let(:can_push_to_branch) { true }
      let(:should_be_rebased) { true }

      before do
        allow(resource).to receive(:source_branch_exists?) { true }
      end

      it 'returns path' do
        is_expected
          .to eq("/#{project.full_path}/-/merge_requests/#{resource.iid}/rebase")
      end
    end

    context 'when cannot rebase' do
      context 'when rebase in progress' do
        let(:rebase_in_progress) { true }
        let(:can_push_to_branch) { true }
        let(:should_be_rebased) { true }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'when user cannot merge' do
        let(:rebase_in_progress) { false }
        let(:can_push_to_branch) { false }
        let(:should_be_rebased) { true }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'should not be rebased' do
        let(:rebase_in_progress) { false }
        let(:can_push_to_branch) { true }
        let(:should_be_rebased) { false }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe '#can_push_to_source_branch' do
    before do
      allow(resource).to receive(:source_branch_exists?) { source_branch_exists }

      allow_any_instance_of(Gitlab::UserAccess::RequestCacheExtension)
        .to receive(:can_push_to_branch?)
              .with(resource.source_branch)
              .and_return(can_push_to_branch)
    end

    subject do
      described_class.new(resource, current_user: user).can_push_to_source_branch?
    end

    context 'when source branch exists AND user can push to source branch' do
      let(:source_branch_exists) { true }
      let(:can_push_to_branch) { true }

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when source branch does not exists' do
      let(:source_branch_exists) { false }
      let(:can_push_to_branch) { true }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when user cannot push to source branch' do
      let(:source_branch_exists) { true }
      let(:can_push_to_branch) { false }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#api_approvals_path' do
    subject { described_class.new(resource, current_user: user).api_approvals_path }

    it { is_expected.to eq(expose_path("/api/v4/projects/#{project.id}/merge_requests/#{resource.iid}/approvals")) }
  end

  describe '#api_approve_path' do
    subject { described_class.new(resource, current_user: user).api_approve_path }

    it { is_expected.to eq(expose_path("/api/v4/projects/#{project.id}/merge_requests/#{resource.iid}/approve")) }
  end

  describe '#api_unapprove_path' do
    subject { described_class.new(resource, current_user: user).api_unapprove_path }

    it { is_expected.to eq(expose_path("/api/v4/projects/#{project.id}/merge_requests/#{resource.iid}/unapprove")) }
  end

  describe '#pipeline_coverage_delta' do
    subject { described_class.new(resource, current_user: user).pipeline_coverage_delta }

    context 'when merge request has pipeline coverage delta' do
      before do
        allow(resource).to receive(:pipeline_coverage_delta).and_return(35.0)
      end

      it 'formats coverage into 2 decimal points' do
        expect(subject).to eq('35.00')
      end
    end

    context 'when merge request does not have pipeline coverage delta' do
      before do
        allow(resource).to receive(:pipeline_coverage_delta).and_return(nil)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#jenkins_integration_active' do
    subject do
      described_class.new(resource, current_user: user)
        .jenkins_integration_active
    end

    context 'when Jenkins integration is active' do
      it 'returns true' do
        allow(resource.source_project).to receive(:jenkins_integration_active?).and_return(true)

        is_expected.to eq(true)
      end
    end

    context 'when Jenkins integration is not active' do
      it 'returns false' do
        allow(resource.source_project).to receive(:jenkins_integration_active?).and_return(false)

        is_expected.to eq(false)
      end
    end
  end
end
