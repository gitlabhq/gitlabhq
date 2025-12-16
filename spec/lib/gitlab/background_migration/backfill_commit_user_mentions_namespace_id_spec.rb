# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCommitUserMentionsNamespaceId,
  feature_category: :code_review_workflow do
  let(:table_name) { :commit_user_mentions }
  let(:constraint_name) { 'check_ddd6f289f4' }
  let(:trigger_name) { 'set_sharding_key_for_commit_user_mentions_on_insert_and_update' }
  let(:note_fk) { :note_id }

  it_behaves_like 'backfill migration for notes children sharding key'

  def record_attrs
    {
      id: table(:commit_user_mentions).count + 1,
      commit_id: OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex)
    }
  end
end
