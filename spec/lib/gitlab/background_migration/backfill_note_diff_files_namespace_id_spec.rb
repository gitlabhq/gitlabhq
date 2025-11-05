# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNoteDiffFilesNamespaceId, feature_category: :code_review_workflow do
  let(:table_name) { :note_diff_files }
  let(:constraint_name) { 'check_ebb23d73d7' }
  let(:trigger_name) { 'trigger_ensure_note_diff_files_sharding_key' }
  let(:note_fk) { :diff_note_id }

  it_behaves_like 'backfill migration for notes children sharding key'

  def record_attrs
    {
      diff: "@@ -6,12 +6,18 @@ module Popen",
      new_path: "files/ruby/popen.rb",
      old_path: "files/ruby/popen.rb",
      a_mode: "100644",
      b_mode: "100644",
      new_file: false,
      renamed_file: false,
      deleted_file: false
    }
  end
end
