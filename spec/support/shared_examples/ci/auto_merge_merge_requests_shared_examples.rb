# frozen_string_literal: true

RSpec.shared_examples 'abort ff merge requests with auto merges' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:source_project) { project }
  let_it_be(:target_project) { project }
  let_it_be(:author) { create_user_from_membership(target_project, :developer) }
  let_it_be(:user) { create(:user) }

  let_it_be(:forked_project) do
    fork_project(target_project, author, repository: true)
  end

  let(:merge_request) do
    create(
      :merge_request,
      author: author,
      source_project: source_project,
      source_branch: 'feature',
      target_branch: 'master',
      target_project: target_project,
      auto_merge_enabled: true,
      auto_merge_strategy: auto_merge_strategy,
      merge_user: user
    )
  end

  let_it_be(:newrev) do
    target_project.repository.create_file(
      user, 'test1.txt', 'Test data', message: 'Test commit', branch_name: 'master'
    )
  end

  let_it_be(:oldrev) do
    target_project
      .repository
      .commit(newrev)
      .parent_id
  end

  let(:refresh_service) { described_class.new(project: project, current_user: user) }

  before do
    target_project.merge_method = merge_method
    target_project.save!
    merge_request.auto_merge_strategy = auto_merge_strategy
    merge_request.save!

    refresh_service.execute(oldrev, newrev, 'refs/heads/master')
    merge_request.reload
  end

  context 'when Project#merge_method is set to FF' do
    let(:merge_method) { :ff }

    it_behaves_like 'aborted merge requests for auto merges'

    context 'with forked project' do
      let(:source_project) { forked_project }

      it_behaves_like 'aborted merge requests for auto merges'
    end

    context 'with bogus auto merge strategy' do
      let(:auto_merge_strategy) { 'bogus' }

      it_behaves_like 'maintained merge requests for auto merges'
    end
  end

  context 'when Project#merge_method is set to rebase_merge' do
    let(:merge_method) { :rebase_merge }

    it_behaves_like 'aborted merge requests for auto merges'

    context 'with forked project' do
      let(:source_project) { forked_project }

      it_behaves_like 'aborted merge requests for auto merges'
    end
  end

  context 'when Project#merge_method is set to merge' do
    let(:merge_method) { :merge }

    it_behaves_like 'maintained merge requests for auto merges'

    context 'with forked project' do
      let(:source_project) { forked_project }

      it_behaves_like 'maintained merge requests for auto merges'
    end
  end
end

RSpec.shared_examples 'aborted merge requests for auto merges' do
  let(:aborted_message) do
    /aborted the automatic merge because target branch was updated/
  end

  it 'aborts auto_merge' do
    expect(merge_request.auto_merge_enabled?).to be_falsey
    expect(merge_request.notes.last.note).to match(aborted_message)
  end

  it 'removes merge_user' do
    expect(merge_request.merge_user).to be_nil
  end

  it 'does not add todos for merge user' do
    expect(user.todos.for_target(merge_request)).to be_empty
  end

  it 'adds todos for merge author' do
    expect(author.todos.for_target(merge_request)).to be_present.and be_all(&:pending?)
  end
end

RSpec.shared_examples 'maintained merge requests for auto merges' do
  it 'does not cancel auto merge' do
    expect(merge_request.auto_merge_enabled?).to be_truthy
    expect(merge_request.notes).to be_empty
  end

  it 'does not change merge_user' do
    expect(merge_request.merge_user).to eq(user)
  end

  it 'does not add todos' do
    expect(author.todos.for_target(merge_request)).to be_empty
    expect(user.todos.for_target(merge_request)).to be_empty
  end
end
