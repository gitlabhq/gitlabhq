# frozen_string_literal: true

RSpec.shared_examples 'reviewer_ids filter' do
  context 'filter_reviewer' do
    let(:opts) { super().merge(reviewer_ids_param) }

    context 'without reviewer_ids' do
      let(:reviewer_ids_param) { {} }

      it 'contains no reviewer_ids' do
        expect(execute.reviewers).to eq []
      end
    end

    context 'with reviewer_ids' do
      let(:reviewer_ids_param) { { reviewer_ids: [reviewer1.id, reviewer2.id] } }

      let(:reviewer1) { create(:user) }
      let(:reviewer2) { create(:user) }

      context 'when the current user can admin the merge_request' do
        context 'with a reviewer who can read the merge_request' do
          before do
            project.add_developer(reviewer1)
          end

          it 'contains reviewers who can read the merge_request' do
            expect(execute.reviewers).to contain_exactly(reviewer1)
          end
        end
      end

      context 'when the current_user cannot admin the merge_request' do
        before do
          project.add_developer(user)
        end

        it 'contains no reviewers' do
          expect(execute.reviewers).to eq []
        end
      end
    end
  end
end

RSpec.shared_examples 'merge request reviewers cache counters invalidator' do
  let(:reviewer_1) { create(:user) }
  let(:reviewer_2) { create(:user) }

  before do
    merge_request.update!(reviewers: [reviewer_1, reviewer_2])
  end

  it 'invalidates counter cache for reviewers' do
    expect(merge_request.reviewers).to all(receive(:invalidate_merge_request_cache_counts))

    described_class.new(project: project, current_user: user).execute(merge_request)
  end
end

RSpec.shared_examples_for 'a service that can create a merge request' do
  subject(:last_mr) { MergeRequest.last }

  it 'creates a merge request with the correct target branch' do
    branch = push_options[:target] || project.default_branch

    expect { service.execute }.to change { MergeRequest.count }.by(1)
    expect(last_mr.target_branch).to eq(branch)
  end

  context 'when project has been forked', :sidekiq_might_not_need_inline do
    let(:forked_project) { fork_project(project, user1, repository: true) }
    let(:service) { described_class.new(project: forked_project, current_user: user1, changes: changes, push_options: push_options) }

    before do
      allow(forked_project).to receive(:empty_repo?).and_return(false)
    end

    it 'sets the correct source and target project' do
      service.execute

      expect(last_mr.source_project).to eq(forked_project)
      expect(last_mr.target_project).to eq(project)
    end
  end
end

RSpec.shared_examples_for 'a service that does not create a merge request' do
  it do
    expect { service.execute }.not_to change { MergeRequest.count }
  end
end

# In the non-foss version of GitLab, there can be many assignees, so
# there 'count' can be something other than 0 or 1. In the foss
# version of GitLab, there can be only one assignee though, so 'count'
# can only be 0 or 1.
RSpec.shared_examples_for 'a service that can change assignees of a merge request' do |count|
  subject(:last_mr) { MergeRequest.last }

  it 'changes assignee count' do
    service.execute

    expect(last_mr.assignees.count).to eq(count)
  end
end

RSpec.shared_examples 'with an existing branch that has a merge request open' do |count|
  let(:changes) { existing_branch_changes }
  let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

  it_behaves_like 'a service that does not create a merge request'
  it_behaves_like 'a service that can change assignees of a merge request', count
end

RSpec.shared_examples 'when coupled with the `create` push option' do |count|
  let(:push_options) { { create: true, assign: assigned, unassign: unassigned } }

  it_behaves_like 'a service that can create a merge request'
  it_behaves_like 'a service that can change assignees of a merge request', count
end

RSpec.shared_examples 'with a new branch' do |count|
  let(:changes) { new_branch_changes }

  it_behaves_like 'a service that does not create a merge request'

  it 'adds an error to the service' do
    service.execute

    expect(service.errors).to include(error_mr_required)
  end

  it_behaves_like 'when coupled with the `create` push option', count
end

RSpec.shared_examples 'with an existing branch but no open MR' do |count|
  let(:changes) { existing_branch_changes }

  it_behaves_like 'a service that does not create a merge request'

  it 'adds an error to the service' do
    service.execute

    expect(service.errors).to include(error_mr_required)
  end

  it_behaves_like 'when coupled with the `create` push option', count
end
