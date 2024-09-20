# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::DeletePlaceholderUserWorker, feature_category: :importers do
  let_it_be(:placeholder_user) { create(:user, :placeholder) }
  let_it_be(:source_user) { create(:import_source_user, placeholder_user: placeholder_user) }

  let(:job_args) { source_user.id }

  subject(:perform) { described_class.new.perform(*job_args) }

  it_behaves_like 'an idempotent worker'

  shared_examples 'deletes the placeholder user' do
    it 'deletes the placeholder_user' do
      expect(DeleteUserWorker).to receive(:perform_async).with(
        placeholder_user.id, placeholder_user.id, { "skip_authorization" => true }
      )

      perform
    end
  end

  shared_examples 'does not delete the placeholder_user and logs the issue' do
    it 'does not delete the placeholder_user and logs the issue' do
      expect(::Import::Framework::Logger).to receive(:warn).with(
        message: 'Unable to delete placeholder user because it is still referenced in other tables',
        source_user_id: source_user.id
      )

      expect(DeleteUserWorker).not_to receive(:perform_async)

      perform
    end
  end

  context 'when no tables reference the user' do
    it_behaves_like 'deletes the placeholder user'
  end

  context 'when another table references the user from an author_id column' do
    let!(:note) { create(:note, author: placeholder_user) }

    it_behaves_like 'does not delete the placeholder_user and logs the issue'
  end

  context 'when another table references the user from a user_id column' do
    let!(:approval) { create(:approval, user: placeholder_user) }

    it_behaves_like 'does not delete the placeholder_user and logs the issue'
  end

  context 'when another table references the user with an ignored column' do
    let!(:note) { create(:note, resolved_by: placeholder_user) }

    it_behaves_like 'deletes the placeholder user'
  end

  context 'when an issue_id happens to equal the placeholder user ID' do
    let!(:issue_assignee) { create(:issue_assignee, issue_id: issue.id) }

    let!(:issue) do
      Issue.find_by_id(placeholder_user.id) || create(:issue, id: placeholder_user.id)
    end

    it_behaves_like 'deletes the placeholder user'
  end

  context 'when there is no placeholder user' do
    let_it_be(:source_user) { create(:import_source_user, :completed, placeholder_user: nil) }

    it 'does not delete the placeholder_user and does not log an issue' do
      expect(::Import::Framework::Logger).not_to receive(:warn)
      expect(DeleteUserWorker).not_to receive(:perform_async)

      perform
    end
  end

  context 'when attempting to delete a user who is not a placeholder' do
    let_it_be(:user) { create(:user, :import_user) }
    let_it_be(:source_user) { create(:import_source_user, placeholder_user: user) }

    it 'does not delete the user' do
      expect(DeleteUserWorker).not_to receive(:perform_async)

      perform
    end
  end
end
