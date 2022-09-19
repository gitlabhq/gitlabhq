# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/bulk_insert'

RSpec.describe RuboCop::Cop::Gitlab::BulkInsert do
  it 'flags the use of ApplicationRecord.legacy_bulk_insert' do
    expect_offense(<<~SOURCE)
      ApplicationRecord.legacy_bulk_insert('merge_request_diff_files', rows)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `BulkInsertSafe` concern, [...]
    SOURCE
  end

  it 'flags the use of ::ApplicationRecord.legacy_bulk_insert' do
    expect_offense(<<~SOURCE)
      ::ApplicationRecord.legacy_bulk_insert('merge_request_diff_files', rows)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `BulkInsertSafe` concern, [...]
    SOURCE
  end
end
