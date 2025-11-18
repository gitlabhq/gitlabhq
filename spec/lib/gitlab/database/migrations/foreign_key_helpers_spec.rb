# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::ForeignKeyHelpers, feature_category: :database do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  describe '#add_concurrent_foreign_key' do
    before do
      allow(model).to receive(:foreign_key_exists?).and_return(false)
    end

    context 'when inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end.to raise_error(RuntimeError)
      end
    end

    context 'when outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'with a target column' do
        it 'defaults to (id) when no custom target column is provided' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          expect(model).to receive(:execute).with(/REFERENCES users \(id\)/)

          model.add_concurrent_foreign_key(:projects, :users,
            column: :user_id)
        end

        it 'references the custom taget column when provided' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          expect(model).to receive(:execute).with(/REFERENCES users \(id_convert_to_bigint\)/)

          model.add_concurrent_foreign_key(:projects, :users,
            column: :user_id,
            target_column: :id_convert_to_bigint)
        end
      end

      context 'with ON DELETE statements' do
        context 'with on_delete: :nullify' do
          it 'appends ON DELETE SET NULL statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON DELETE SET NULL/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_delete: :nullify)
          end
        end

        context 'with on_delete: :cascade' do
          it 'appends ON DELETE CASCADE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON DELETE CASCADE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_delete: :cascade)
          end
        end

        context 'with on_delete: nil' do
          it 'appends no ON DELETE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).not_to receive(:execute).with(/ON DELETE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_delete: nil)
          end
        end
      end

      context 'with ON UPDATE statements' do
        context 'with on_update: :nullify' do
          it 'appends ON UPDATE SET NULL statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON UPDATE SET NULL/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_update: :nullify)
          end
        end

        context 'with on_update: :cascade' do
          it 'appends ON UPDATE CASCADE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with(/ON UPDATE CASCADE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_update: :cascade)
          end
        end

        context 'with on_update: nil' do
          it 'appends no ON UPDATE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).not_to receive(:execute).with(/ON UPDATE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id,
              on_update: nil)
          end
        end

        context 'when on_update is not provided' do
          it 'appends no ON UPDATE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).not_to receive(:execute).with(/ON UPDATE/)

            model.add_concurrent_foreign_key(:projects, :users,
              column: :user_id)
          end
        end
      end

      context 'when no custom key name is supplied' do
        it 'creates a concurrent foreign key and validates it' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/NOT VALID/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end

        it 'does not create a foreign key if it exists already' do
          name = model.concurrent_foreign_key_name(:projects, :user_id)
          expect(model).to receive(:foreign_key_exists?).with(:projects, :users,
            column: :user_id,
            on_update: nil,
            on_delete: :cascade,
            name: name,
            primary_key: :id).and_return(true)

          expect(model).not_to receive(:execute).with(/ADD CONSTRAINT/)
          expect(model).to receive(:execute).with(/VALIDATE CONSTRAINT/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end
      end

      context 'when a custom key name is supplied' do
        context 'for creating a new foreign key for a column that does not presently exist' do
          it 'creates a new foreign key' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/NOT VALID/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+foo/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :foo)
          end
        end

        context 'for creating a duplicate foreign key for a column that presently exists' do
          context 'when the supplied key name is the same as the existing foreign key name' do
            it 'does not create a new foreign key' do
              expect(model).to receive(:foreign_key_exists?).with(:projects, :users,
                name: :foo,
                primary_key: :id,
                on_update: nil,
                on_delete: :cascade,
                column: :user_id).and_return(true)

              expect(model).not_to receive(:execute).with(/ADD CONSTRAINT/)
              expect(model).to receive(:execute).with(/VALIDATE CONSTRAINT/)

              model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :foo)
            end
          end

          context 'when the supplied key name is different from the existing foreign key name' do
            it 'creates a new foreign key' do
              expect(model).to receive(:with_lock_retries).and_call_original
              expect(model).to receive(:disable_statement_timeout).and_call_original
              expect(model).to receive(:statement_timeout_disabled?).and_return(false)
              expect(model).to receive(:execute).with(/SET statement_timeout TO/)
              expect(model).to receive(:execute).ordered.with(/NOT VALID/)
              expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+bar/)
              expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

              model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :bar)
            end
          end
        end
      end

      describe 'validate option' do
        let(:args) { [:projects, :users] }
        let(:options) { { column: :user_id, on_delete: nil } }

        context 'when validate is supplied with a falsey value' do
          it_behaves_like 'skips validation', validate: false
          it_behaves_like 'skips validation', validate: nil
        end

        context 'when validate is supplied with a truthy value' do
          it_behaves_like 'performs validation', validate: true
          it_behaves_like 'performs validation', validate: :whatever
        end

        context 'when validate is not supplied' do
          it_behaves_like 'performs validation', {}
        end

        context "when a ForeignKeyViolation occurs" do
          let(:source) { 'projects' }
          let(:constraint_name) { 'fk_projects_users_id' }
          let(:options) { { column: :user_id, name: constraint_name } }

          it "drops the constraint and raises an error", :aggregate_failures do
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(
              "ALTER TABLE projects ADD CONSTRAINT fk_projects_users_id FOREIGN KEY (user_id) REFERENCES users (id) " \
                "ON DELETE CASCADE NOT VALID;"
            )
            expect(model).to receive(:execute).with(/SET statement_timeout TO/).ordered
            expect(model).to receive(:execute).with(/ALTER TABLE .* VALIDATE CONSTRAINT/)
              .and_raise(PG::ForeignKeyViolation.new("foreign key violation")).ordered
            expect(model).to receive(:execute).with(/RESET statement_timeout/).ordered
            expect(model).to receive(:execute).with(/ALTER TABLE #{source} DROP CONSTRAINT #{constraint_name}/).ordered

            expect do
              model.add_concurrent_foreign_key(source, :users, **options)
            end.to raise_error %r{Migration failed intentionally due to ForeignKeyViolation}
          end
        end
      end

      context 'when the reverse_lock_order flag is set' do
        it 'explicitly locks the tables in target-source order', :aggregate_failures do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          expect(model).to receive(:execute).with('LOCK TABLE users, projects IN SHARE ROW EXCLUSIVE MODE')
          expect(model).to receive(:execute).with(/REFERENCES users \(id\)/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id, reverse_lock_order: true)
        end
      end

      context 'when creating foreign key for a group of columns' do
        it 'references the custom target columns when provided', :aggregate_failures do
          expect(model).to receive(:with_lock_retries).and_yield
          expect(model).to receive(:execute).with(
            "ALTER TABLE projects " \
              "ADD CONSTRAINT fk_multiple_columns " \
              "FOREIGN KEY \(partition_number, user_id\) " \
              "REFERENCES users \(partition_number, id\) " \
              "ON UPDATE CASCADE " \
              "ON DELETE CASCADE " \
              "NOT VALID;"
          )

          model.add_concurrent_foreign_key(
            :projects,
            :users,
            column: [:partition_number, :user_id],
            target_column: [:partition_number, :id],
            validate: false,
            name: :fk_multiple_columns,
            on_update: :cascade
          )
        end

        context 'when foreign key is already defined' do
          it 'does not create foreign key', :aggregate_failures do
            expect(model).to receive(:foreign_key_exists?).with(
              :projects,
              :users,
              {
                column: [:partition_number, :user_id],
                name: :fk_multiple_columns,
                on_update: :cascade,
                on_delete: :cascade,
                primary_key: [:partition_number, :id]
              }
            ).and_return(true)

            expect(model).not_to receive(:with_lock_retries).and_yield
            expect(model).not_to receive(:execute).with(/FOREIGN KEY/)

            model.add_concurrent_foreign_key(
              :projects,
              :users,
              column: [:partition_number, :user_id],
              target_column: [:partition_number, :id],
              on_update: :cascade,
              validate: false,
              name: :fk_multiple_columns
            )
          end
        end
      end

      context 'when creating foreign key on a partitioned table' do
        let(:source) { :_test_source_partitioned_table }
        let(:dest) { :_test_dest_partitioned_table }
        let(:args) { [source, dest] }
        let(:options) { { column: [:partition_id, :owner_id], target_column: [:partition_id, :id] } }

        before do
          model.execute(<<~SQL)
            CREATE TABLE public.#{source} (
              id serial NOT NULL,
              partition_id serial NOT NULL,
              owner_id bigint NOT NULL,
              PRIMARY KEY (id, partition_id)
            ) PARTITION BY LIST(partition_id);

            CREATE TABLE #{source}_1
              PARTITION OF public.#{source}
              FOR VALUES IN (1);

            CREATE TABLE public.#{dest} (
              id serial NOT NULL,
              partition_id serial NOT NULL,
              PRIMARY KEY (id, partition_id)
            );
          SQL
        end

        it 'creates the FK without using NOT VALID', :aggregate_failures do
          allow(model).to receive(:execute).and_call_original

          expect(model).to receive(:with_lock_retries).and_yield

          expect(model).to receive(:execute).with(
            "ALTER TABLE #{source} " \
              "ADD CONSTRAINT fk_multiple_columns " \
              "FOREIGN KEY \(partition_id, owner_id\) " \
              "REFERENCES #{dest} \(partition_id, id\) " \
              "ON UPDATE CASCADE ON DELETE CASCADE ;"
          )

          model.add_concurrent_foreign_key(
            *args,
            name: :fk_multiple_columns,
            on_update: :cascade,
            allow_partitioned: true,
            **options
          )
        end

        it 'raises an error if allow_partitioned is not set' do
          expect(model).not_to receive(:with_lock_retries).and_yield
          expect(model).not_to receive(:execute).with(/FOREIGN KEY/)

          expect { model.add_concurrent_foreign_key(*args, **options) }
            .to raise_error ArgumentError, /use add_concurrent_partitioned_foreign_key/
        end

        context 'when the reverse_lock_order flag is set' do
          it 'explicitly locks the tables in target-source order', :aggregate_failures do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/SET statement_timeout TO/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

            expect(model).to receive(:execute).with("LOCK TABLE #{dest}, #{source} IN ACCESS EXCLUSIVE MODE")
            expect(model).to receive(:execute).with(/REFERENCES #{dest} \(partition_id, id\)/)

            model.add_concurrent_foreign_key(*args, reverse_lock_order: true, allow_partitioned: true, **options)
          end
        end
      end
    end
  end

  describe '#concurrent_foreign_key_name' do
    it 'returns the name for a foreign key' do
      name = model.concurrent_foreign_key_name(:this_is_a_very_long_table_name,
        :with_a_very_long_column_name)

      expect(name).to be_an_instance_of(String)
      expect(name.length).to eq(13)
    end

    context 'when using multiple columns' do
      it 'returns the name of the foreign key', :aggregate_failures do
        result = model.concurrent_foreign_key_name(:table_name, [:partition_number, :id])

        expect(result).to be_an_instance_of(String)
        expect(result.length).to eq(13)
      end
    end
  end

  describe '#foreign_key_exists?' do
    let(:referenced_table_name) { :_test_gitlab_main_referenced }
    let(:referencing_table_name) { :_test_gitlab_main_referencing }
    let(:schema) { 'public' }
    let(:identifier) { "#{schema}.#{referencing_table_name}" }

    before do
      model.connection.execute(<<~SQL)
        create table #{referenced_table_name} (
          id bigserial primary key not null
        );
        create table #{referencing_table_name} (
          id bigserial primary key not null,
          non_standard_id bigint not null,
          constraint fk_referenced foreign key (non_standard_id)
            references #{referenced_table_name}(id) on delete cascade
        );
      SQL
    end

    shared_examples_for 'foreign key checks' do
      it 'finds existing foreign keys by column' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, column: :non_standard_id)).to be_truthy
      end

      it 'finds existing foreign keys by name' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced)).to be_truthy
      end

      it 'finds existing foreign_keys by name and column' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced,
          column: :non_standard_id)).to be_truthy
      end

      it 'finds existing foreign_keys by name, column and on_delete' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced,
          column: :non_standard_id, on_delete: :cascade)).to be_truthy
      end

      it 'finds existing foreign keys by target table only' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table)).to be_truthy
      end

      it 'finds existing foreign_keys by identifier' do
        expect(model.foreign_key_exists?(identifier, target_table)).to be_truthy
      end

      it 'compares by column name if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, column: :user_id)).to be_falsey
      end

      it 'compares by target column name if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, primary_key: :user_id)).to be_falsey
        expect(model.foreign_key_exists?(referencing_table_name, target_table, primary_key: :id)).to be_truthy
      end

      it 'compares by foreign key name if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table,
          name: :non_existent_foreign_key_name)).to be_falsey
      end

      it 'compares by foreign key name and column if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :non_existent_foreign_key_name,
          column: :non_standard_id)).to be_falsey
      end

      it 'compares by foreign key name, column and on_delete if given' do
        expect(model.foreign_key_exists?(referencing_table_name, target_table, name: :fk_referenced,
          column: :non_standard_id, on_delete: :nullify)).to be_falsey
      end
    end

    context 'without specifying a target table' do
      let(:target_table) { nil }

      it_behaves_like 'foreign key checks'
    end

    context 'when specifying a target table' do
      let(:target_table) { referenced_table_name }

      it_behaves_like 'foreign key checks'
    end

    it 'compares by target table if no column given' do
      expect(model.foreign_key_exists?(:projects, :other_table)).to be_falsey
    end

    it 'raises an error if an invalid on_delete is specified' do
      # The correct on_delete key is "nullify"
      expect { model.foreign_key_exists?(referenced_table_name, on_delete: :set_null) }.to raise_error(ArgumentError)
    end

    context 'with foreign key using multiple columns' do
      let(:p_referenced_table_name) { :_test_gitlab_main_p_referenced }
      let(:p_referencing_table_name) { :_test_gitlab_main_p_referencing }

      before do
        model.connection.execute(<<~SQL)
          create table #{p_referenced_table_name} (
            id bigserial not null,
            partition_number bigint not null default 100,
            primary key (partition_number, id)
          );
          create table #{p_referencing_table_name} (
            id bigserial primary key not null,
            partition_number bigint not null,
            constraint fk_partitioning foreign key (partition_number, id)
              references #{p_referenced_table_name} (partition_number, id) on delete cascade
          );
        SQL
      end

      it 'finds existing foreign keys by columns' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          column: [:partition_number, :id])).to be_truthy
      end

      it 'finds existing foreign keys by name' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning)).to be_truthy
      end

      it 'finds existing foreign_keys by name and column' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning, column: [:partition_number, :id])).to be_truthy
      end

      it 'finds existing foreign_keys by name, column and on_delete' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning, column: [:partition_number, :id], on_delete: :cascade)).to be_truthy
      end

      it 'finds existing foreign keys by target table only' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name)).to be_truthy
      end

      it 'compares by column name if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          column: :id)).to be_falsey
      end

      it 'compares by target column name if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          primary_key: :user_id)).to be_falsey
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          primary_key: [:partition_number, :id])).to be_truthy
      end

      it 'compares by foreign key name if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :non_existent_foreign_key_name)).to be_falsey
      end

      it 'compares by foreign key name and column if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :non_existent_foreign_key_name, column: [:partition_number, :id])).to be_falsey
      end

      it 'compares by foreign key name, column and on_delete if given' do
        expect(model.foreign_key_exists?(p_referencing_table_name, p_referenced_table_name,
          name: :fk_partitioning, column: [:partition_number, :id], on_delete: :nullify)).to be_falsey
      end
    end
  end

  describe '#remove_foreign_key_if_exists' do
    context 'when the foreign key does not exist' do
      before do
        allow(model).to receive(:foreign_key_exists?).and_return(false)
      end

      it 'does nothing' do
        expect(model).not_to receive(:remove_foreign_key)

        model.remove_foreign_key_if_exists(:projects, :users, column: :user_id)
      end
    end

    context 'when the foreign key exists' do
      before do
        allow(model).to receive(:foreign_key_exists?).and_return(true)
      end

      it 'removes the foreign key' do
        expect(model).to receive(:remove_foreign_key).with(:projects, :users, { column: :user_id })

        model.remove_foreign_key_if_exists(:projects, :users, column: :user_id)
      end

      context 'when the target table is not given' do
        it 'passes the options as the second parameter' do
          expect(model).to receive(:remove_foreign_key).with(:projects, { column: :user_id })

          model.remove_foreign_key_if_exists(:projects, column: :user_id)
        end
      end

      context 'when the reverse_lock_order option is given' do
        it 'requests for lock before removing the foreign key' do
          expect(model).to receive(:transaction_open?).and_return(true)
          expect(model).to receive(:execute).with(/LOCK TABLE users, projects/)
          expect(model).not_to receive(:remove_foreign_key).with(:projects, :users)

          model.remove_foreign_key_if_exists(:projects, :users, column: :user_id, reverse_lock_order: true)
        end

        context 'when not inside a transaction' do
          it 'does not lock' do
            expect(model).to receive(:transaction_open?).and_return(false)
            expect(model).not_to receive(:execute).with(/LOCK TABLE users, projects/)
            expect(model).to receive(:remove_foreign_key).with(:projects, :users, { column: :user_id })

            model.remove_foreign_key_if_exists(:projects, :users, column: :user_id, reverse_lock_order: true)
          end
        end
      end
    end
  end
end
