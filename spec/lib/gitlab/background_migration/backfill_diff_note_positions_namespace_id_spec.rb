# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDiffNotePositionsNamespaceId,
  feature_category: :code_review_workflow do
  let(:table_name) { :diff_note_positions }
  let(:constraint_name) { 'check_4c86140f48' }
  let(:trigger_name) { 'set_sharding_key_for_diff_note_positions_on_insert_and_update' }
  let(:note_fk) { :note_id }

  it_behaves_like 'backfill migration for notes children sharding key'

  def record_attrs
    {
      base_sha: 'base',
      start_sha: 'start',
      head_sha: 'head',
      old_path: "path/to/file",
      new_path: "path/to/file",
      diff_content_type: [0, 1].sample, # pick a random type, corresponding to 'text' or 'image'
      diff_type: 2, # pick the only available type, corresponding to 'head'
      line_code: "bd4b7bfff3a247ccf6e3371c41ec018a55230bcc_534_521"
    }
  end
end
