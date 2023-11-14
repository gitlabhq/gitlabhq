# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::WraparoundAutovacuum, feature_category: :database do
  include Database::DatabaseHelpers

  let(:migration) do
    Class.new(Gitlab::Database::Migration[2.1])
         .include(described_class)
         .new
  end

  describe '#can_execute_on?' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :jh, :dev_or_test, :wraparound_prevention, :expectation) do
      true  | true  | true  | true  | false
      true  | true  | false | true  | false
      false | true  | true  | true  | false
      false | true  | false | true  | false
      true  | true  | true  | false | true
      true  | true  | false | false | false
      false | true  | true  | false | true
      false | true  | false | false | false

      true  | false | true  | true  | false
      true  | false | false | true  | false
      false | false | true  | true  | false
      false | false | false | true  | false
      true  | false | true  | false | true
      true  | false | false | false | true
      false | false | true  | false | true
      false | false | false | false | false
    end

    with_them do
      it 'returns as expected for GitLab.com, dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:jh?).and_return(jh)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)
        allow(migration).to receive(:wraparound_prevention_on_tables?).with([:table]).and_return(wraparound_prevention)

        expect(migration.can_execute_on?(:table)).to eq(expectation)
      end
    end
  end

  describe '#wraparound_prevention_on_tables?' do
    before do
      swapout_view_for_table(:postgres_autovacuum_activity, connection: ApplicationRecord.connection)
      create(:postgres_autovacuum_activity, table: 'foo', wraparound_prevention: false)
      create(:postgres_autovacuum_activity, table: 'bar', wraparound_prevention: true)
    end

    it { expect(migration.wraparound_prevention_on_tables?([:foo])).to be_falsey }
    it { expect(migration.wraparound_prevention_on_tables?([:bar])).to be_truthy }
    it { expect(migration.wraparound_prevention_on_tables?([:foo, :bar])).to be_truthy }
  end
end
