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
        expect(subject.pluck('relname')).to eq(['pg_stat_statements'])
      end
    end
  end
end
