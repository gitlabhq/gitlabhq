# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/clickhouse'

RSpec.describe Tooling::Danger::Clickhouse, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:migration_files) do
    %w[
      db/click_house/20220901010203_add_widgets_table.rb
      db/click_house/20220909010203_add_properties_column.rb
      db/click_house/20220910010203_drop_tools_table.rb
      db/click_house/20220912010203_add_index_to_widgets_table.rb
    ]
  end

  subject(:clickhouse) { fake_danger.new(helper: fake_helper) }

  describe '#changes' do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        'with click_house gem changes' => {
          modified_files: %w[gems/click_house-client/lib/click_house/client.rb],
          changes_by_category: {
            database: [],
            clickhouse: %w[gems/click_house-client/lib/click_house/client.rb]
          },
          impacted_files: %w[gems/click_house-client/lib/click_house/client.rb]
        },
        'with clickhouse data changes' => {
          modified_files: %w[db/clickhouse/20230720114001_add_magic_table_migration.rb],
          changes_by_category: {
            database: [],
            clickhouse: %w[db/clickhouse/20230720114001_add_magic_table_migration.rb]
          },
          impacted_files: %w[db/clickhouse/20230720114001_add_magic_table_migration.rb]
        },
        'with clickhouse app changes' => {
          modified_files: %w[lib/click_house/query_builder.rb],
          changes_by_category: {
            database: [],
            clickhouse: %w[lib/click_house/query_builder.rb]
          },
          impacted_files: %w[lib/click_house/query_builder.rb]
        }
      }
    end

    with_them do
      before do
        allow(fake_helper).to receive(:modified_files).and_return(modified_files)
        allow(fake_helper).to receive(:all_changed_files).and_return(modified_files)
        allow(fake_helper).to receive(:changes_by_category).and_return(changes_by_category)
      end

      it 'returns only clickhouse changes' do
        expect(clickhouse.changes).to match impacted_files
      end
    end
  end
end
