# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PgDepend, type: :model, feature_category: :database do
  let(:connection) { described_class.connection }

  describe '.from_pg_extension' do
    subject { described_class.from_pg_extension('VIEW') }

    context 'when having views as dependency' do
      before do
        connection.execute('CREATE EXTENSION IF NOT EXISTS pg_stat_statements;')
      end

      it 'returns pg_stat_statements' do
        expected_views = ['pg_stat_statements']

        if Gitlab::Database::Reflection.new(described_class).version.to_f >= 14
          expected_views << 'pg_stat_statements_info' # View added by pg_stat_statements starting in postgres 14
        end

        expect(subject.pluck('relname')).to match_array(expected_views)
      end
    end
  end
end
