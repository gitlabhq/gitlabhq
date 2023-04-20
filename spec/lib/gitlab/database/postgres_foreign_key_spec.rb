# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresForeignKey, type: :model, feature_category: :database do
  # PostgresForeignKey does not `behaves_like 'a postgres model'` because it does not correspond 1-1 with a single entry
  # in pg_class

  let(:table_prefix) { '_test_gitlab_main' }

  before do
    ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE #{schema_table_name('referenced_table')} (
        id bigserial primary key not null,
        id_b bigserial not null,
        UNIQUE (id, id_b)
      );

      CREATE TABLE #{schema_table_name('other_referenced_table')} (
        id bigserial primary key not null
      );

      CREATE TABLE #{schema_table_name('constrained_table')} (
        id bigserial primary key not null,
        referenced_table_id bigint not null,
        referenced_table_id_b bigint not null,
        other_referenced_table_id bigint not null,
        CONSTRAINT fk_constrained_to_referenced
          FOREIGN KEY(referenced_table_id, referenced_table_id_b)
          REFERENCES #{table_name('referenced_table')}(id, id_b)
          ON DELETE restrict
          ON UPDATE restrict,
        CONSTRAINT fk_constrained_to_other_referenced FOREIGN KEY(other_referenced_table_id)
           REFERENCES #{table_name('other_referenced_table')}(id)
      );

    SQL
  end

  describe '#by_referenced_table_identifier' do
    it 'throws an error when the identifier name is not fully qualified' do
      expect { described_class.by_referenced_table_identifier(table_name("referenced_table")) }.to raise_error(ArgumentError, /not fully qualified/)
    end

    it 'finds the foreign keys for the referenced table' do
      expected = described_class.find_by!(name: 'fk_constrained_to_referenced')

      expect(described_class.by_referenced_table_identifier(schema_table_name("referenced_table"))).to contain_exactly(expected)
    end
  end

  describe '#by_referenced_table_name' do
    it 'finds the foreign keys for the referenced table' do
      expected = described_class.find_by!(name: 'fk_constrained_to_referenced')

      expect(described_class.by_referenced_table_name(table_name("referenced_table"))).to contain_exactly(expected)
    end
  end

  describe '#by_constrained_table_identifier' do
    it 'throws an error when the identifier name is not fully qualified' do
      expect { described_class.by_constrained_table_identifier(table_name("constrained_table")) }.to raise_error(ArgumentError, /not fully qualified/)
    end

    it 'finds the foreign keys for the constrained table' do
      expected = described_class.where(name: %w[fk_constrained_to_referenced fk_constrained_to_other_referenced]).to_a

      expect(described_class.by_constrained_table_identifier(schema_table_name('constrained_table'))).to match_array(expected)
    end
  end

  describe '#by_constrained_table_name' do
    let(:expected) { described_class.where(name: %w[fk_constrained_to_referenced fk_constrained_to_other_referenced]).to_a }

    it 'finds the foreign keys for the constrained table' do
      expect(described_class.by_constrained_table_name(table_name("constrained_table"))).to match_array(expected)
    end
  end

  describe '#by_constrained_table_name_or_identifier' do
    let(:expected) { described_class.where(name: %w[fk_constrained_to_referenced fk_constrained_to_other_referenced]).to_a }

    context 'when using table name' do
      it 'finds the foreign keys for the constrained table' do
        expect(described_class.by_constrained_table_name_or_identifier(table_name("constrained_table"))).to match_array(expected)
      end
    end

    context 'when using identifier' do
      it 'finds the foreign keys for the constrained table' do
        expect(described_class.by_constrained_table_name_or_identifier(schema_table_name('constrained_table'))).to match_array(expected)
      end
    end
  end

  describe '#by_name' do
    it 'finds foreign keys by name' do
      expect(described_class.by_name('fk_constrained_to_referenced').pluck(:name)).to contain_exactly('fk_constrained_to_referenced')
    end
  end

  context 'when finding columns for foreign keys' do
    using RSpec::Parameterized::TableSyntax

    let(:fks) { described_class.by_constrained_table_name(table_name("constrained_table")) }

    where(:fk, :expected_constrained, :expected_referenced) do
      lazy { described_class.find_by(name: 'fk_constrained_to_referenced') } | %w[referenced_table_id referenced_table_id_b] | %w[id id_b]
      lazy { described_class.find_by(name: 'fk_constrained_to_other_referenced') } | %w[other_referenced_table_id] | %w[id]
    end

    with_them do
      it 'finds the correct constrained column names' do
        expect(fk.constrained_columns).to eq(expected_constrained)
      end

      it 'finds the correct referenced column names' do
        expect(fk.referenced_columns).to eq(expected_referenced)
      end

      describe '#by_constrained_columns' do
        it 'finds the correct foreign key' do
          expect(fks.by_constrained_columns(expected_constrained)).to contain_exactly(fk)
        end
      end

      describe '#by_referenced_columns' do
        it 'finds the correct foreign key' do
          expect(fks.by_referenced_columns(expected_referenced)).to contain_exactly(fk)
        end
      end
    end
  end

  describe '#on_delete_action and #on_update_action' do
    before do
      ApplicationRecord.connection.execute(<<~SQL)
        create table #{schema_table_name('referenced_table_all_on_delete_actions')} (
          id bigserial primary key not null
        );

        create table #{schema_table_name('constrained_table_all_on_delete_actions')} (
          id bigserial primary key not null,
          ref_id_no_action bigint not null constraint fk_no_action
            references #{table_name('referenced_table_all_on_delete_actions')}(id),
          ref_id_restrict bigint not null constraint fk_restrict
            references #{table_name('referenced_table_all_on_delete_actions')}(id)
            on delete restrict on update restrict,
          ref_id_nullify bigint not null constraint fk_nullify
            references #{table_name('referenced_table_all_on_delete_actions')}(id)
            on delete set null on update set null,
          ref_id_cascade bigint not null constraint fk_cascade
            references #{table_name('referenced_table_all_on_delete_actions')}(id)
            on delete cascade on update cascade,
          ref_id_set_default bigint not null constraint fk_set_default
            references #{table_name('referenced_table_all_on_delete_actions')}(id)
            on delete set default on update set default
        )
      SQL
    end

    let(:fks) { described_class.by_constrained_table_name(table_name('constrained_table_all_on_delete_actions')) }

    context 'with an invalid on_delete_action' do
      it 'raises an error' do
        # the correct value is :nullify, not :set_null
        expect { fks.by_on_delete_action(:set_null) }.to raise_error(ArgumentError)
      end
    end

    where(:fk_name, :expected_action) do
      [
        %w[fk_no_action no_action],
        %w[fk_restrict restrict],
        %w[fk_nullify nullify],
        %w[fk_cascade cascade],
        %w[fk_set_default set_default]
      ]
    end

    with_them do
      subject(:fk) { fks.find_by(name: fk_name) }

      it 'has the appropriate on delete action' do
        expect(fk.on_delete_action).to eq(expected_action)
      end

      it 'has the appropriate on update action' do
        expect(fk.on_update_action).to eq(expected_action)
      end

      describe '#by_on_delete_action' do
        it 'finds the key by on delete action' do
          expect(fks.by_on_delete_action(expected_action)).to contain_exactly(fk)
        end
      end

      describe '#by_on_update_action' do
        it 'finds the key by on update action' do
          expect(fks.by_on_update_action(expected_action)).to contain_exactly(fk)
        end
      end
    end
  end

  context 'when supporting foreign keys on partitioned tables' do
    before do
      ApplicationRecord.connection.execute(<<~SQL)
        create table #{schema_table_name('parent')} (
          id bigserial primary key not null
        ) partition by hash(id);

        create table #{schema_table_name('child')} partition of #{table_name('parent')}
          for values with (modulus 2, remainder 1);

        create table #{schema_table_name('referencing_partitioned')} (
          id bigserial not null primary key,
          constraint fk_inherited foreign key (id) references #{table_name('parent')}(id)
        )
      SQL
    end

    describe '#is_inherited' do
      using RSpec::Parameterized::TableSyntax

      where(:fk, :inherited) do
        lazy { described_class.find_by(name: 'fk_inherited') } | false
        lazy { described_class.by_referenced_table_identifier(schema_table_name('child')).first! } | true
        lazy { described_class.find_by(name: 'fk_constrained_to_referenced') } | false
      end

      with_them do
        it 'has the appropriate inheritance value' do
          expect(fk.is_inherited).to eq(inherited)
        end
      end
    end

    describe '#not_inherited' do
      let(:fks) { described_class.by_constrained_table_identifier(schema_table_name('referencing_partitioned')) }

      it 'lists all non-inherited foreign keys' do
        expect(fks.pluck(:referenced_table_name)).to contain_exactly(table_name('parent'), table_name('child'))
        expect(fks.not_inherited.pluck(:referenced_table_name)).to contain_exactly(table_name('parent'))
      end
    end
  end

  context 'with two tables both partitioned' do
    before do
      ApplicationRecord.connection.execute(<<~SQL)
        create table #{table_name('parent')} (
          id bigserial primary key not null
        ) partition by hash(id);

        create table #{table_name('child')}
        partition of #{table_name('parent')} for values with (remainder 1, modulus 2);

        create table #{table_name('ref_parent')} (
            id bigserial primary key not null
        ) partition by hash(id);

        create table #{table_name('ref_child_1')}
        partition of #{table_name('ref_parent')} for values with (remainder 1, modulus 3);

        create table #{table_name('ref_child_2')}
        partition of #{table_name('ref_parent')} for values with (remainder 2, modulus 3);

        alter table #{table_name('parent')} add constraint fk foreign key (id) references #{table_name('ref_parent')} (id);
      SQL
    end

    describe '#child_foreign_keys' do
      it 'is the child foreign keys of the partitioned parent fk' do
        fk = described_class.by_constrained_table_name(table_name('parent')).first
        children = fk.child_foreign_keys
        expect(children.count).to eq(1)
        expect(children.first.constrained_table_name).to eq(table_name('child'))
      end
    end
  end

  def schema_table_name(name)
    "public.#{table_name(name)}"
  end

  def table_name(name)
    "#{table_prefix}_#{name}"
  end
end
