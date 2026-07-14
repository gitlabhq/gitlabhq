# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MarkDoneFinalizedMergeRequestTodos,
  :use_clean_rails_memory_store_caching, feature_category: :notifications do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:merge_requests) { table(:merge_requests) }
  let(:todos) { table(:todos) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) do
    namespaces.create!(name: 'name', path: 'path', type: 'Group', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(name: 'project', path: 'project', organization_id: organization.id,
      project_namespace_id: namespace.id, namespace_id: namespace.id)
  end

  let(:author) { create_user('author') }
  let(:user) { create_user('user') }

  let(:merged_mr) { create_merge_request(state_id: 3) }
  let(:closed_mr) { create_merge_request(state_id: 2) }
  let(:open_mr) { create_merge_request(state_id: 1) }

  let(:migration_args) do
    {
      start_cursor: [0],
      end_cursor: [todos.maximum(:id)],
      batch_table: :todos,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  describe '#perform' do
    [1, 5, 9, 13].each do |action|
      it "marks pending action #{action} to-dos on merged merge requests as done" do
        todo = create_todo(target: merged_mr, action: action)

        perform_migration

        expect(todo.reload).to have_attributes(state: 'done', resolved_by_action: 0)
      end

      it "marks pending action #{action} to-dos on closed merge requests as done" do
        todo = create_todo(target: closed_mr, action: action)

        perform_migration

        expect(todo.reload).to have_attributes(state: 'done', resolved_by_action: 0)
      end
    end

    it 'clears snoozed_until when resolving a to-do' do
      snoozed_todo = create_todo(target: merged_mr, action: 9, snoozed_until: 1.day.from_now)

      perform_migration

      expect(snoozed_todo.reload).to have_attributes(state: 'done', snoozed_until: nil)
    end

    it 'bumps updated_at when resolving a to-do' do
      stale_time = 1.year.ago
      todo = create_todo(target: merged_mr, action: 9, created_at: stale_time, updated_at: stale_time)

      perform_migration

      expect(todo.reload.updated_at).to be_within(1.minute).of(Time.current)
    end

    it 'leaves to-dos on open merge requests pending' do
      open_todo = create_todo(target: open_mr, action: 9)

      perform_migration

      expect(open_todo.reload.state).to eq('pending')
    end

    it 'leaves to-dos on locked merge requests pending' do
      locked_mr = create_merge_request(state_id: 4)
      locked_todo = create_todo(target: locked_mr, action: 9)

      perform_migration

      expect(locked_todo.reload.state).to eq('pending')
    end

    it 'leaves to-dos with non-resolvable actions pending' do
      mentioned_todo = create_todo(target: merged_mr, action: 2) # MENTIONED

      perform_migration

      expect(mentioned_todo.reload.state).to eq('pending')
    end

    it 'leaves non-merge-request to-dos pending even for resolvable actions' do
      issue_todo = create_todo(target: merged_mr, target_type: 'Issue', action: 1)

      perform_migration

      expect(issue_todo.reload.state).to eq('pending')
    end

    it 'leaves already-done to-dos untouched' do
      done_todo = create_todo(target: merged_mr, action: 9, state: 'done')

      perform_migration

      expect(done_todo.reload.state).to eq('done')
    end

    it 'invalidates the cached pending count only for affected users', :aggregate_failures do
      affected_todo = create_todo(target: merged_mr, action: 9)
      other_user = create_user('other')
      create_todo(target: open_mr, action: 9, user_id: other_user.id)

      Rails.cache.write(['users', affected_todo.user_id, 'todos_pending_count'], 5)
      Rails.cache.write(['users', other_user.id, 'todos_pending_count'], 5)

      perform_migration

      expect(Rails.cache.read(['users', affected_todo.user_id, 'todos_pending_count'])).to be_nil
      expect(Rails.cache.read(['users', other_user.id, 'todos_pending_count'])).to eq(5)
    end

    it 'resolves to-dos and invalidates caches for every affected user across sub-batches', :aggregate_failures do
      second_user = create_user('second')
      todo_for_user = create_todo(target: merged_mr, action: 9, user_id: user.id)
      todo_for_second_user = create_todo(target: closed_mr, action: 1, user_id: second_user.id)

      Rails.cache.write(['users', user.id, 'todos_pending_count'], 5)
      Rails.cache.write(['users', second_user.id, 'todos_pending_count'], 5)

      perform_migration(sub_batch_size: 1)

      expect(todo_for_user.reload.state).to eq('done')
      expect(todo_for_second_user.reload.state).to eq('done')
      expect(Rails.cache.read(['users', user.id, 'todos_pending_count'])).to be_nil
      expect(Rails.cache.read(['users', second_user.id, 'todos_pending_count'])).to be_nil
    end
  end

  def perform_migration(sub_batch_size: 100)
    described_class.new(**migration_args.merge(sub_batch_size: sub_batch_size)).perform
  end

  def create_user(name)
    users.create!(username: name, email: "#{name}@gitlab.com", projects_limit: 10,
      organization_id: organization.id)
  end

  def create_merge_request(state_id:)
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: "feature-#{SecureRandom.hex(4)}",
      state_id: state_id
    )
  end

  def create_todo(target:, action:, target_type: 'MergeRequest', state: 'pending', user_id: user.id, **extra)
    todos.create!(
      {
        user_id: user_id,
        author_id: author.id,
        action: action,
        target_type: target_type,
        target_id: target.id,
        state: state,
        organization_id: organization.id
      }.merge(extra)
    )
  end
end
