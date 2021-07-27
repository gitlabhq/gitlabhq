# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresForeignKey, type: :model do
  # PostgresForeignKey does not `behaves_like 'a postgres model'` because it does not correspond 1-1 with a single entry
  # in pg_class

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
    CREATE TABLE public.referenced_table (
      id bigserial primary key not null
    );

    CREATE TABLE public.other_referenced_table (
      id bigserial primary key not null
    );

    CREATE TABLE public.constrained_table (
      id bigserial primary key not null,
      referenced_table_id bigint not null,
      other_referenced_table_id bigint not null,
      CONSTRAINT fk_constrained_to_referenced FOREIGN KEY(referenced_table_id) REFERENCES referenced_table(id),
      CONSTRAINT fk_constrained_to_other_referenced FOREIGN KEY(other_referenced_table_id)
         REFERENCES other_referenced_table(id)
    );
    SQL
  end

  describe '#by_referenced_table_identifier' do
    it 'throws an error when the identifier name is not fully qualified' do
      expect { described_class.by_referenced_table_identifier('referenced_table') }.to raise_error(ArgumentError, /not fully qualified/)
    end

    it 'finds the foreign keys for the referenced table' do
      expected = described_class.find_by!(name: 'fk_constrained_to_referenced')

      expect(described_class.by_referenced_table_identifier('public.referenced_table')).to contain_exactly(expected)
    end
  end
end
