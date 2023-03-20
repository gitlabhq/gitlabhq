# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsCiBuildNeedsBigIntConversion, feature_category: :continuous_integration do
  describe '#up' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :jh, :swap) do
      true  | true  | true  | false
      true  | false | true  | false
      false | true  | true  | false
      false | false | true  | false
      true  | true  | false | true
      true  | false | false | true
      false | true  | false | true
      false | false | false | false
    end

    with_them do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id TYPE integer')
        connection.execute('ALTER TABLE ci_build_needs ALTER COLUMN id_convert_to_bigint TYPE bigint')
      end

      it 'swaps the integer and bigint columns for GitLab.com, dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)
        allow(Gitlab).to receive(:jh?).and_return(jh)

        ci_build_needs = table(:ci_build_needs)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              ci_build_needs.reset_column_information

              expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
              expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
            }

            migration.after -> {
              ci_build_needs.reset_column_information

              if swap
                expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
                expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('integer')
              else
                expect(ci_build_needs.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
                expect(ci_build_needs.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
              end
            }
          end
        end
      end
    end
  end
end
