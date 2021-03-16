# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/bulk_insert'

RSpec.describe RuboCop::Cop::Gitlab::BulkInsert do
  subject(:cop) { described_class.new }

  it 'flags the use of Gitlab::Database.bulk_insert' do
    expect_offense(<<~SOURCE)
      Gitlab::Database.bulk_insert('merge_request_diff_files', rows)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `BulkInsertSafe` concern, [...]
    SOURCE
  end

  it 'flags the use of ::Gitlab::Database.bulk_insert' do
    expect_offense(<<~SOURCE)
      ::Gitlab::Database.bulk_insert('merge_request_diff_files', rows)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `BulkInsertSafe` concern, [...]
    SOURCE
  end
end
