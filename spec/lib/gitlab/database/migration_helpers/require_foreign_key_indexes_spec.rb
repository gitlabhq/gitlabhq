# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::RequireForeignKeyIndexes, feature_category: :database do
  let(:migration_class) do
    klass = Class.new(Gitlab::Database::Migration[2.4]) do
      milestone '19.5'
    end
    klass.instance_variable_set(:@_defining_file, 'db/migrate/0_test.rb')
    klass
  end

  let(:model) { migration_class.new }
  let(:only_index) { 'index_test_fk_children_on_parent_id' }

  before do
    allow(model).to receive(:puts)
    allow(model).to receive(:transaction_open?).and_return(false)
    allow(model).to receive(:disable_statement_timeout).and_call_original

    model.connection.execute(<<~SQL)
      CREATE TABLE _test_fk_index_parents (id bigserial PRIMARY KEY);
      CREATE TABLE _test_fk_index_children (
        id bigserial PRIMARY KEY,
        parent_id bigint NOT NULL CONSTRAINT fk_test_parents REFERENCES _test_fk_index_parents(id),
        other_id bigint
      );
      CREATE INDEX #{only_index} ON _test_fk_index_children (parent_id);
    SQL
  end

  describe '#remove_concurrent_index_by_name' do
    it 'raises when dropping the only index supporting the foreign key' do
      expect(model).not_to receive(:remove_index)

      expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index) }
        .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_parents/)
    end

    it 'removes the index when another index covers the foreign key' do
      model.connection.execute('CREATE INDEX idx_cover ON _test_fk_index_children (parent_id, other_id)')

      expect(model).to receive(:remove_index)
        .with(:_test_fk_index_children, { algorithm: :concurrently, name: only_index })

      model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index)
    end

    it 'raises when the other index does not lead with the foreign key column' do
      model.connection.execute('CREATE INDEX idx_not_leading ON _test_fk_index_children (other_id, parent_id)')

      expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index) }
        .to raise_error(ArgumentError, /only index supporting the foreign key/)
    end

    it 'raises when the other index is partial on an unrelated condition' do
      model.connection.execute(
        'CREATE INDEX idx_partial ON _test_fk_index_children (parent_id) WHERE other_id IS NOT NULL'
      )

      expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index) }
        .to raise_error(ArgumentError, /only index supporting the foreign key/)
    end

    it 'removes the index when the other index is partial only on the foreign key presence' do
      model.connection.execute(
        'CREATE INDEX idx_fk_partial ON _test_fk_index_children (parent_id) WHERE parent_id IS NOT NULL'
      )

      expect(model).to receive(:remove_index)
        .with(:_test_fk_index_children, { algorithm: :concurrently, name: only_index })

      model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index)
    end

    it 'removes an index that does not support any foreign key' do
      model.connection.execute('CREATE INDEX idx_other ON _test_fk_index_children (other_id)')

      expect(model).to receive(:remove_index)
        .with(:_test_fk_index_children, { algorithm: :concurrently, name: 'idx_other' })

      model.remove_concurrent_index_by_name(:_test_fk_index_children, 'idx_other')
    end

    it 'removes the index when the primary key covers the foreign key' do
      model.connection.execute(<<~SQL)
        CREATE TABLE _test_fk_index_profiles (
          id bigint PRIMARY KEY CONSTRAINT fk_test_profile_parents REFERENCES _test_fk_index_parents(id)
        );
        CREATE INDEX idx_profile_id ON _test_fk_index_profiles (id);
      SQL

      expect(model).to receive(:remove_index)
        .with(:_test_fk_index_profiles, { algorithm: :concurrently, name: 'idx_profile_id' })

      model.remove_concurrent_index_by_name(:_test_fk_index_profiles, 'idx_profile_id')
    end

    context 'with an invalid index' do
      def invalidate_index(index_name)
        model.connection.execute(<<~SQL)
          UPDATE pg_index SET indisvalid = false WHERE indexrelid = '#{index_name}'::regclass
        SQL
      end

      it 'removes an invalid index even when it is the only one on the foreign key' do
        invalidate_index(only_index)

        expect(model).to receive(:remove_index)
          .with(:_test_fk_index_children, { algorithm: :concurrently, name: only_index })

        model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index)
      end

      it 'raises when the only other covering index is invalid' do
        model.connection.execute('CREATE INDEX idx_invalid_cover ON _test_fk_index_children (parent_id, other_id)')
        invalidate_index('idx_invalid_cover')

        expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index) }
          .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_parents/)
      end
    end

    context 'with an expression index' do
      it 'raises when dropping the only expression index leading with the foreign key column' do
        model.connection.execute(<<~SQL)
          DROP INDEX #{only_index};
          CREATE INDEX idx_expr_cover ON _test_fk_index_children (parent_id, abs(other_id));
        SQL

        expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, 'idx_expr_cover') }
          .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_parents/)
      end

      it 'counts an expression index leading with the foreign key column as remaining coverage' do
        model.connection.execute('CREATE INDEX idx_expr_cover ON _test_fk_index_children (parent_id, abs(other_id))')

        expect(model).to receive(:remove_index)
          .with(:_test_fk_index_children, { algorithm: :concurrently, name: only_index })

        model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index)
      end

      it 'does not count an expression index that does not lead with the foreign key column' do
        model.connection.execute('CREATE INDEX idx_expr_noncover ON _test_fk_index_children (abs(other_id), parent_id)')

        expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index) }
          .to raise_error(ArgumentError, /only index supporting the foreign key/)
      end
    end

    context 'with a composite foreign key' do
      before do
        model.connection.execute(<<~SQL)
          CREATE TABLE _test_fk_index_p2 (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            PRIMARY KEY (partition_id, id)
          );
          CREATE TABLE _test_fk_index_c2 (
            id bigserial PRIMARY KEY,
            parent_id bigint NOT NULL,
            partition_id bigint NOT NULL,
            CONSTRAINT fk_test_composite FOREIGN KEY (partition_id, parent_id)
              REFERENCES _test_fk_index_p2 (partition_id, id)
          );
          CREATE INDEX idx_c2_composite ON _test_fk_index_c2 (parent_id, partition_id);
        SQL
      end

      it 'raises when no other index covers both columns' do
        expect { model.remove_concurrent_index_by_name(:_test_fk_index_c2, 'idx_c2_composite') }
          .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_composite/)
      end

      it 'removes the index when a permuted composite index covers the foreign key' do
        model.connection.execute('CREATE INDEX idx_c2_permuted ON _test_fk_index_c2 (partition_id, parent_id, id)')

        expect(model).to receive(:remove_index)
          .with(:_test_fk_index_c2, { algorithm: :concurrently, name: 'idx_c2_composite' })

        model.remove_concurrent_index_by_name(:_test_fk_index_c2, 'idx_c2_composite')
      end
    end

    context 'with a CI partitioned composite foreign key' do
      before do
        model.connection.execute(<<~SQL)
          CREATE TABLE _test_gitlab_ci_pfk_parents (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            PRIMARY KEY (partition_id, id)
          );
          CREATE TABLE _test_gitlab_ci_pfk_children (
            id bigserial PRIMARY KEY,
            parent_id bigint NOT NULL,
            partition_id bigint NOT NULL,
            CONSTRAINT fk_test_ci_partitioned FOREIGN KEY (partition_id, parent_id)
              REFERENCES _test_gitlab_ci_pfk_parents (partition_id, id)
          );
          CREATE INDEX idx_ci_pfk_composite ON _test_gitlab_ci_pfk_children (partition_id, parent_id);
        SQL
      end

      it 'allows dropping the composite index while an index on the non-partition column remains' do
        model.connection.execute('CREATE INDEX idx_ci_pfk_parent ON _test_gitlab_ci_pfk_children (parent_id)')

        expect(model).to receive(:remove_index)
          .with(:_test_gitlab_ci_pfk_children, { algorithm: :concurrently, name: 'idx_ci_pfk_composite' })

        model.remove_concurrent_index_by_name(:_test_gitlab_ci_pfk_children, 'idx_ci_pfk_composite')
      end

      it 'raises when the composite index is the last one supporting the foreign key' do
        expect { model.remove_concurrent_index_by_name(:_test_gitlab_ci_pfk_children, 'idx_ci_pfk_composite') }
          .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_ci_partitioned/)
      end

      it 'raises when dropping the last index on the non-partition column' do
        model.connection.execute(<<~SQL)
          DROP INDEX idx_ci_pfk_composite;
          CREATE INDEX idx_ci_pfk_parent ON _test_gitlab_ci_pfk_children (parent_id);
        SQL

        expect { model.remove_concurrent_index_by_name(:_test_gitlab_ci_pfk_children, 'idx_ci_pfk_parent') }
          .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_ci_partitioned/)
      end
    end
  end

  describe 'guard bypass branches' do
    it 'steps aside on ambiguous column matches so the remove_index error wins' do
      model.connection.execute('CREATE UNIQUE INDEX idx_dup_parent ON _test_fk_index_children (parent_id)')

      expect { model.remove_concurrent_index(:_test_fk_index_children, :parent_id) }
        .to raise_error(ArgumentError, /Multiple indexes found/)
    end

    it 'raises through the guard when the index name is passed as a hash' do
      expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, name: only_index) }
        .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_parents/)
    end

    it 'prefers the transaction error over the guard for removal by name' do
      allow(model).to receive(:transaction_open?).and_return(true)

      expect { model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index) }
        .to raise_error(RuntimeError, /can not be run inside a transaction/)
    end

    it 'defers to the base error when scheduling an async removal without a name' do
      expect { model.prepare_async_index_removal(:_test_fk_index_children, :parent_id, name: nil) }
        .to raise_error(/must get an index name defined/)
    end
  end

  describe '#prepare_async_index_removal' do
    it 'raises when scheduling removal of the only index supporting the foreign key' do
      expect { model.prepare_async_index_removal(:_test_fk_index_children, :parent_id, name: only_index) }
        .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_parents/)
    end
  end

  describe '#remove_concurrent_index' do
    it 'raises when dropping the only index supporting the foreign key by column' do
      expect(model).not_to receive(:remove_index)

      expect { model.remove_concurrent_index(:_test_fk_index_children, :parent_id) }
        .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_parents/)
    end

    it 'prefers the transaction error over the guard inside a transaction' do
      allow(model).to receive(:transaction_open?).and_return(true)

      expect { model.remove_concurrent_index(:_test_fk_index_children, :parent_id) }
        .to raise_error(RuntimeError, /can not be run inside a transaction/)
    end

    it 'prefers the partition-table error over the guard' do
      model.connection.execute(<<~SQL)
        CREATE TABLE _test_fk_ipart_parent (
          id bigserial NOT NULL,
          parent_id bigint,
          PRIMARY KEY (id)
        ) PARTITION BY RANGE (id);

        CREATE TABLE _test_fk_ipart_01 PARTITION OF _test_fk_ipart_parent FOR VALUES FROM (1) TO (100);

        ALTER TABLE _test_fk_ipart_01
          ADD CONSTRAINT fk_test_ipart FOREIGN KEY (parent_id) REFERENCES _test_fk_index_parents(id);

        CREATE INDEX _test_ipart01_parent_idx ON _test_fk_ipart_01 (parent_id);
      SQL

      expect { model.remove_concurrent_index(:_test_fk_ipart_01, :parent_id) }
        .to raise_error(ArgumentError, /use remove_concurrent_partitioned_index_by_name/)
    end
  end

  describe '#remove_concurrent_partitioned_index_by_name' do
    let(:migration_class) do
      klass = Class.new(Gitlab::Database::Migration[2.4]) do
        milestone '19.5'
        include Gitlab::Database::PartitioningMigrationHelpers
      end
      klass.instance_variable_set(:@_defining_file, 'db/migrate/0_test.rb')
      klass
    end

    let(:partitioned_index) { '_test_partitioned_parent_id_idx' }

    before do
      model.connection.execute(<<~SQL)
        CREATE TABLE _test_fk_index_partitioned (
          id bigserial NOT NULL,
          created_at timestamptz NOT NULL,
          parent_id bigint,
          PRIMARY KEY (id, created_at),
          CONSTRAINT fk_test_partitioned_parents FOREIGN KEY (parent_id) REFERENCES _test_fk_index_parents(id)
        ) PARTITION BY RANGE (created_at);

        CREATE INDEX #{partitioned_index} ON _test_fk_index_partitioned (parent_id);
      SQL
    end

    it 'raises when dropping the only index supporting the foreign key' do
      expect(model).not_to receive(:remove_index)

      expect { model.remove_concurrent_partitioned_index_by_name(:_test_fk_index_partitioned, partitioned_index) }
        .to raise_error(ArgumentError, /only index supporting the foreign key fk_test_partitioned_parents/)
    end

    context 'when the migration predates the guard' do
      let(:migration_class) do
        klass = Class.new(Gitlab::Database::Migration[2.3]) do
          milestone '19.5'
          include Gitlab::Database::PartitioningMigrationHelpers
        end
        klass.instance_variable_set(:@_defining_file, 'db/migrate/0_test.rb')
        klass
      end

      it 'removes the index without the guard' do
        allow(model).to receive(:with_lock_retries).and_yield
        expect(model).to receive(:remove_index).with(:_test_fk_index_partitioned, name: partitioned_index)

        model.remove_concurrent_partitioned_index_by_name(:_test_fk_index_partitioned, partitioned_index)
      end
    end
  end

  describe 'version gating' do
    context 'with Gitlab::Database::Migration[2.3]' do
      let(:migration_class) do
        klass = Class.new(Gitlab::Database::Migration[2.3]) do
          milestone '19.5'
        end
        klass.instance_variable_set(:@_defining_file, 'db/migrate/0_test.rb')
        klass
      end

      it 'removes the last supporting index without the guard' do
        expect(model).to receive(:remove_index)
          .with(:_test_fk_index_children, { algorithm: :concurrently, name: only_index })

        model.remove_concurrent_index_by_name(:_test_fk_index_children, only_index)
      end
    end
  end
end
