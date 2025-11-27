# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSuggestionsNamespaceId, feature_category: :code_review_workflow do
  let(:table_name) { :suggestions }
  let(:constraint_name) { 'check_e69372e45f' }
  let(:trigger_name) { 'set_sharding_key_for_suggestions_on_insert_and_update' }
  let(:note_fk) { :note_id }

  it_behaves_like 'backfill migration for notes children sharding key'

  def record_attrs
    {
      relative_order: migration_table.count - 1,
      from_content: "\n",
      to_content: "# v1 change\n"
    }
  end
end
