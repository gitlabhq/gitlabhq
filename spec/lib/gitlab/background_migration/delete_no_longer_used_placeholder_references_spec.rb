# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Needed in specs
RSpec.describe Gitlab::BackgroundMigration::DeleteNoLongerUsedPlaceholderReferences, feature_category: :importers do
  subject(:background_migration) do
    described_class.new(
      start_id: placeholder_references.minimum(:id),
      end_id: placeholder_references.maximum(:id),
      batch_table: :import_source_user_placeholder_references,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:placeholder_references) { table(:import_source_user_placeholder_references) }
  let(:users) { table(:users) }
  let(:import_source_users) { table(:import_source_users) }

  let(:organization) { organizations.create!(name: 'Organization', path: 'organization-path') }
  let(:namespace) { namespaces.create!(name: 'Namespace', path: 'namespace-path', organization_id: organization.id) }

  let(:placeholder_user) do
    users.create!(user_type: HasUserType::USER_TYPES[:placeholder], name: 'placeholder user',
      email: 'placeholder_user_1@example.com', organization_id: organization.id, projects_limit: 1)
  end

  let(:import_user) do
    users.create!(user_type: HasUserType::USER_TYPES[:import_user], name: 'import user',
      email: 'import_user_1@example.com', organization_id: organization.id, projects_limit: 1)
  end

  let(:placeholder_source_user) do
    import_source_users.create!(
      namespace_id: namespace.id,
      placeholder_user_id: placeholder_user.id,
      source_user_identifier: SecureRandom.uuid,
      source_hostname: 'https://gitlab.com',
      source_name: 'User 1',
      source_username: 'user1',
      import_type: 'gitlab_migration'
    )
  end

  let(:import_user_source_user) do
    import_source_users.create!(
      namespace_id: namespace.id,
      placeholder_user_id: import_user.id,
      source_user_identifier: SecureRandom.uuid,
      source_hostname: 'https://gitlab.com',
      source_name: 'User 3',
      source_username: 'user3',
      import_type: 'gitlab_migration'
    )
  end

  # Placeholder user references
  let!(:approval_reference) { create_placeholder_reference('Approval', 'user_id', placeholder_source_user) }
  let!(:award_emoji_reference) { create_placeholder_reference('AwardEmoji', 'user_id', placeholder_source_user) }
  let!(:event_reference) { create_placeholder_reference('Event', 'author_id', placeholder_source_user) }
  let!(:epic_author_reference) { create_placeholder_reference('Epic', 'author_id', placeholder_source_user) }
  let!(:epic_assignee_reference) { create_placeholder_reference('Epic', 'assignee_id', placeholder_source_user) }
  let!(:issue_author_reference) { create_placeholder_reference('Issue', 'author_id', placeholder_source_user) }

  let!(:pipeline_schedule_reference) do
    create_placeholder_reference('Ci::PipelineSchedule', 'owner_id', placeholder_source_user)
  end

  let!(:merge_request_updated_by_reference) do
    create_placeholder_reference('MergeRequest', 'updated_by_id', placeholder_source_user)
  end

  let!(:note_reference) do
    create_placeholder_reference('Note', 'author_id', placeholder_source_user)
  end

  let!(:not_mapped_reference_1) do
    create_placeholder_reference('Note', 'user_id', placeholder_source_user)
  end

  let!(:not_mapped_reference_2) do
    create_placeholder_reference('Model', 'author_id', placeholder_source_user)
  end

  # Import user references
  let!(:import_user_reference) { create_placeholder_reference('Approval', 'user_id', import_user_source_user) }
  let!(:import_user_approval_reference) { create_placeholder_reference('Approval', 'user_id', import_user_source_user) }
  let!(:import_user_award_emoji_reference) do
    create_placeholder_reference('AwardEmoji', 'user_id', import_user_source_user)
  end

  let!(:import_user_event_reference) { create_placeholder_reference('Event', 'author_id', import_user_source_user) }
  let!(:import_user_epic_author_reference) do
    create_placeholder_reference('Epic', 'author_id', import_user_source_user)
  end

  let!(:import_user_epic_assignee_reference) do
    create_placeholder_reference('Epic', 'assignee_id', import_user_source_user)
  end

  let!(:import_user_issue_author_reference) do
    create_placeholder_reference('Issue', 'author_id', import_user_source_user)
  end

  let!(:import_user_pipeline_schedule_reference) do
    create_placeholder_reference('Ci::PipelineSchedule', 'owner_id', import_user_source_user)
  end

  let!(:import_user_merge_request_updated_by_reference) do
    create_placeholder_reference('MergeRequest', 'updated_by_id', import_user_source_user)
  end

  let!(:import_user_note_reference) do
    create_placeholder_reference('Note', 'author_id', import_user_source_user)
  end

  def create_placeholder_reference(model, user_reference_column, source_user)
    placeholder_references.create!(
      model: model,
      user_reference_column: user_reference_column,
      source_user_id: source_user.id,
      namespace_id: namespace.id,
      alias_version: 1,
      numeric_key: 1
    )
  end

  describe '#perform' do
    it 'deletes only placeholder user references which are listed' do
      expect { background_migration }.to change { placeholder_references.count }.by(-9)

      # Deleted placeholder references
      expect { approval_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { award_emoji_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { event_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { epic_author_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { epic_assignee_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { issue_author_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { pipeline_schedule_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { merge_request_updated_by_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { note_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # Does not delete not listed reference
      expect(not_mapped_reference_1.reload).to be_persisted
      expect(not_mapped_reference_2.reload).to be_persisted

      # Does not delete import user references
      expect(import_user_approval_reference.reload).to be_persisted
      expect(import_user_award_emoji_reference.reload).to be_persisted
      expect(import_user_event_reference.reload).to be_persisted
      expect(import_user_epic_author_reference.reload).to be_persisted
      expect(import_user_epic_assignee_reference.reload).to be_persisted
      expect(import_user_issue_author_reference.reload).to be_persisted
      expect(import_user_pipeline_schedule_reference.reload).to be_persisted
      expect(import_user_merge_request_updated_by_reference.reload).to be_persisted
      expect(import_user_note_reference.reload).to be_persisted
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
