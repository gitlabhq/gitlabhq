# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/database'

RSpec.describe Tooling::Danger::Database, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:migration_files) do
    [
      # regular migrations
      'db/migrate/20220901010203_add_widgets_table.rb',
      'db/migrate/20220909010203_add_properties_column.rb',
      'db/migrate/20220910010203_drop_tools_table.rb',
      'db/migrate/20220912010203_add_index_to_widgets_table.rb',

      # post migrations
      'db/post_migrate/20220901010203_add_widgets_table.rb',
      'db/post_migrate/20220909010203_add_properties_column.rb',
      'db/post_migrate/20220910010203_drop_tools_table.rb',
      'db/post_migrate/20220912010203_add_index_to_widgets_table.rb',

      # ee migrations
      'ee/db/migrate/20220901010203_add_widgets_table.rb',
      'ee/db/migrate/20220909010203_add_properties_column.rb',
      'ee/db/migrate/20220910010203_drop_tools_table.rb',
      'ee/db/migrate/20220912010203_add_index_to_widgets_table.rb',

      # geo migrations
      'ee/db/geo/migrate/20220901010203_add_widgets_table.rb',
      'ee/db/geo/migrate/20220909010203_add_properties_column.rb',
      'ee/db/geo/migrate/20220910010203_drop_tools_table.rb',
      'ee/db/geo/migrate/20220912010203_add_index_to_widgets_table.rb'
    ]
  end

  let(:cutoff) { Date.parse('2022-10-01') - 21 }

  subject(:database) { fake_danger.new }

  describe '#find_migration_files_before' do
    it 'returns migrations that are before the cutoff' do
      expect(database.find_migration_files_before(migration_files, cutoff).length).to eq(8)
    end
  end
end
