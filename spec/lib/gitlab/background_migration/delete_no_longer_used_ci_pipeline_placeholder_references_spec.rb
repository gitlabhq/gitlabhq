# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteNoLongerUsedCiPipelinePlaceholderReferences,
  feature_category: :importers do
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

  # Placeholder user references to be deleted
  let!(:bridge_reference) { create_placeholder_reference('Ci::Bridge', 'user_id', placeholder_source_user) }
  let!(:build_reference) { create_placeholder_reference('Ci::Build', 'user_id', placeholder_source_user) }
  let!(:generic_reference) { create_placeholder_reference('GenericCommitStatus', 'user_id', placeholder_source_user) }
  let!(:project_snippet_reference) do
    create_placeholder_reference('ProjectSnippet', 'author_id', placeholder_source_user)
  end

  let!(:work_item_reference_author) { create_placeholder_reference('WorkItem', 'author_id', placeholder_source_user) }
  let!(:work_item_reference_updated_by) do
    create_placeholder_reference('WorkItem', 'updated_by_id', placeholder_source_user)
  end

  let!(:work_item_reference_closed_by) do
    create_placeholder_reference('WorkItem', 'closed_by_id', placeholder_source_user)
  end

  # Placeholder user reference to be maintained
  let!(:approval_reference) { create_placeholder_reference('Approval', 'user_id', placeholder_source_user) }
  let!(:ci_build_reference_erased_by) do
    create_placeholder_reference('Ci::Bridge', 'erased_by_id', placeholder_source_user)
  end

  let!(:work_item_reference_last_edited_by) do
    create_placeholder_reference('WorkItem', 'last_edited_by_id', placeholder_source_user)
  end

  # Import user references
  let!(:import_user_bridge_reference) { create_placeholder_reference('Ci::Bridge', 'user_id', import_user_source_user) }
  let!(:import_user_build_reference) { create_placeholder_reference('Ci::Build', 'user_id', import_user_source_user) }
  let!(:import_user_generic_reference) do
    create_placeholder_reference('GenericCommitStatus', 'user_id', import_user_source_user)
  end

  let!(:import_user_work_item_reference) do
    create_placeholder_reference('WorkItem', 'author_id', import_user_source_user)
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
    it 'deletes only expected placeholder user references' do
      expect { background_migration }.to change { placeholder_references.count }.by(-7)

      # Deleted placeholder references
      expect { bridge_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { build_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { generic_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { project_snippet_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { work_item_reference_author.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { work_item_reference_updated_by.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { work_item_reference_closed_by.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # Does not delete unexpected user_reference_column
      expect(approval_reference.reload).to be_persisted
      expect(ci_build_reference_erased_by.reload).to be_persisted
      expect(work_item_reference_last_edited_by.reload).to be_persisted

      # Does not delete import user references
      expect(import_user_bridge_reference.reload).to be_persisted
      expect(import_user_build_reference.reload).to be_persisted
      expect(import_user_generic_reference.reload).to be_persisted
      expect(import_user_work_item_reference.reload).to be_persisted
    end
  end
end
