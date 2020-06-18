# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/bulk_insert'

describe RuboCop::Cop::Gitlab::BulkInsert do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of Gitlab::Database.bulk_insert' do
    expect_offense(<<~SOURCE)
    Gitlab::Database.bulk_insert('merge_request_diff_files', rows)
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `BulkInsertSafe` concern, instead of using `Gitlab::Database.bulk_insert`. See https://docs.gitlab.com/ee/development/insert_into_tables_in_batches.html
    SOURCE
  end
end
