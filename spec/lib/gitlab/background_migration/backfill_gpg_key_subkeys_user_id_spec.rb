# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGpgKeySubkeysUserId, feature_category: :source_code_management do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :gpg_key_subkeys }
    let(:backfill_column) { :user_id }
    let(:backfill_via_table) { :gpg_keys }
    let(:backfill_via_column) { :user_id }
    let(:backfill_via_foreign_key) { :gpg_key_id }
  end
end
