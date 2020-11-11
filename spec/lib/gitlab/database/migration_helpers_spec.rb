# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  describe '#remove_timestamps' do
    it 'can remove the default timestamps' do
      Gitlab::Database::MigrationHelpers::DEFAULT_TIMESTAMP_COLUMNS.each do |column_name|
        expect(model).to receive(:remove_column).with(:foo, column_name)
      end

      model.remove_timestamps(:foo)
    end

    it 'can remove custom timestamps' do
      expect(model).to receive(:remove_column).with(:foo, :bar)

      model.remove_timestamps(:foo, columns: [:bar])
    end
  end

  describe '#add_timestamps_with_timezone' do
    let(:in_transaction) { false }

    before do
      allow(model).to receive(:transaction_open?).and_return(in_transaction)
      allow(model).to receive(:disable_statement_timeout)
    end

    it 'adds "created_at" and "updated_at" fields with the "datetime_with_timezone" data type' do
      Gitlab::Database::MigrationHelpers::DEFAULT_TIMESTAMP_COLUMNS.each do |column_name|
        expect(model).to receive(:add_column).with(:foo, column_name, :datetime_with_timezone, { null: false })
      end

      model.add_timestamps_with_timezone(:foo)
    end

    it 'can disable the NOT NULL constraint' do
      Gitlab::Database::MigrationHelpers::DEFAULT_TIMESTAMP_COLUMNS.each do |column_name|
        expect(model).to receive(:add_column).with(:foo, column_name, :datetime_with_timezone, { null: true })
      end

      model.add_timestamps_with_timezone(:foo, null: true)
    end

    it 'can add just one column' do
      expect(model).to receive(:add_column).with(:foo, :created_at, :datetime_with_timezone, anything)
      expect(model).not_to receive(:add_column).with(:foo, :updated_at, :datetime_with_timezone, anything)

      model.add_timestamps_with_timezone(:foo, columns: [:created_at])
    end

    it 'can add choice of acceptable columns' do
      expect(model).to receive(:add_column).with(:foo, :created_at, :datetime_with_timezone, anything)
      expect(model).to receive(:add_column).with(:foo, :deleted_at, :datetime_with_timezone, anything)
      expect(model).not_to receive(:add_column).with(:foo, :updated_at, :datetime_with_timezone, anything)

      model.add_timestamps_with_timezone(:foo, columns: [:created_at, :deleted_at])
    end

    it 'cannot add unacceptable column names' do
      expect do
        model.add_timestamps_with_timezone(:foo, columns: [:bar])
      end.to raise_error %r/Illegal timestamp column name/
    end

    context 'in a transaction' do
      let(:in_transaction) { true }

      before do
        allow(model).to receive(:add_column).with(any_args).and_call_original
        allow(model).to receive(:add_column)
          .with(:foo, anything, :datetime_with_timezone, anything)
          .and_return(nil)
      end

      it 'cannot add a default value' do
        expect do
          model.add_timestamps_with_timezone(:foo, default: :i_cause_an_error)
        end.to raise_error %r/add_timestamps_with_timezone/
      end

      it 'can add columns without defaults' do
        expect do
          model.add_timestamps_with_timezone(:foo)
        end.not_to raise_error
      end
    end
  end

  describe '#add_concurrent_index' do
    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:disable_statement_timeout).and_call_original
      end

      it 'creates the index concurrently' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, algorithm: :concurrently)

        model.add_concurrent_index(:users, :foo)
      end

      it 'creates unique index concurrently' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, { algorithm: :concurrently, unique: true })

        model.add_concurrent_index(:users, :foo, unique: true)
      end

      it 'does nothing if the index exists already' do
        expect(model).to receive(:index_exists?)
          .with(:users, :foo, { algorithm: :concurrently, unique: true }).and_return(true)
        expect(model).not_to receive(:add_index)

        model.add_concurrent_index(:users, :foo, unique: true)
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.add_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#remove_concurrent_index' do
    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:index_exists?).and_return(true)
        allow(model).to receive(:disable_statement_timeout).and_call_original
      end

      describe 'by column name' do
        it 'removes the index concurrently' do
          expect(model).to receive(:remove_index)
            .with(:users, { algorithm: :concurrently, column: :foo })

          model.remove_concurrent_index(:users, :foo)
        end

        it 'does nothing if the index does not exist' do
          expect(model).to receive(:index_exists?)
            .with(:users, :foo, { algorithm: :concurrently, unique: true }).and_return(false)
          expect(model).not_to receive(:remove_index)

          model.remove_concurrent_index(:users, :foo, unique: true)
        end

        describe 'by index name' do
          before do
            allow(model).to receive(:index_exists_by_name?).with(:users, "index_x_by_y").and_return(true)
          end

          it 'removes the index concurrently by index name' do
            expect(model).to receive(:remove_index)
              .with(:users, { algorithm: :concurrently, name: "index_x_by_y" })

            model.remove_concurrent_index_by_name(:users, "index_x_by_y")
          end

          it 'does nothing if the index does not exist' do
            expect(model).to receive(:index_exists_by_name?).with(:users, "index_x_by_y").and_return(false)
            expect(model).not_to receive(:remove_index)

            model.remove_concurrent_index_by_name(:users, "index_x_by_y")
          end

          it 'removes the index with keyword arguments' do
            expect(model).to receive(:remove_index)
              .with(:users, { algorithm: :concurrently, name: "index_x_by_y" })

            model.remove_concurrent_index_by_name(:users, name: "index_x_by_y")
          end

          it 'raises an error if the index is blank' do
            expect do
              model.remove_concurrent_index_by_name(:users, wrong_key: "index_x_by_y")
            end.to raise_error 'remove_concurrent_index_by_name must get an index name as the second argument'
          end
        end
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.remove_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#add_concurrent_foreign_key' do
    before do
      allow(model).to receive(:foreign_key_exists?).and_return(false)
    end

    context 'inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end.to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'ON DELETE statements' do
        context 'on_delete: :nullify' do
          it 'appends ON DELETE SET NULL statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET ALL/)

            expect(model).to receive(:execute).with(/ON DELETE SET NULL/)

            model.add_concurrent_foreign_key(:projects, :users,
                                             column: :user_id,
                                             on_delete: :nullify)
          end
        end

        context 'on_delete: :cascade' do
          it 'appends ON DELETE CASCADE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET ALL/)

            expect(model).to receive(:execute).with(/ON DELETE CASCADE/)

            model.add_concurrent_foreign_key(:projects, :users,
                                             column: :user_id,
                                             on_delete: :cascade)
          end
        end

        context 'on_delete: nil' do
          it 'appends no ON DELETE statement' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:statement_timeout_disabled?).and_return(false)
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).ordered.with(/RESET ALL/)

            expect(model).not_to receive(:execute).with(/ON DELETE/)

            model.add_concurrent_foreign_key(:projects, :users,
                                             column: :user_id,
                                             on_delete: nil)
          end
        end
      end

      context 'when no custom key name is supplied' do
        it 'creates a concurrent foreign key and validates it' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/statement_timeout/)
          expect(model).to receive(:execute).ordered.with(/NOT VALID/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET ALL/)

          model.add_concurrent_foreign_key(:projects, :users, column: :user_id)
        end

        it 'does not create a foreign key if it exists already' do
          name = model.concurrent_foreign_key_name(:projects, :user_id)
          expect(model).to receive(:foreign_key_exists?).with(:projects, :users,
                                                              column: :user_id,
                                                              on_delete: :cascade,
                                                              name: name).and_return(true)

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
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/NOT VALID/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+foo/)
            expect(model).to receive(:execute).ordered.with(/RESET ALL/)

            model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :foo)
          end
        end

        context 'for creating a duplicate foreign key for a column that presently exists' do
          context 'when the supplied key name is the same as the existing foreign key name' do
            it 'does not create a new foreign key' do
              expect(model).to receive(:foreign_key_exists?).with(:projects, :users,
                                                                  name: :foo,
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
              expect(model).to receive(:execute).with(/statement_timeout/)
              expect(model).to receive(:execute).ordered.with(/NOT VALID/)
              expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+bar/)
              expect(model).to receive(:execute).ordered.with(/RESET ALL/)

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
      end
    end
  end

  describe '#validate_foreign_key' do
    context 'when name is provided' do
      it 'does not infer the foreign key constraint name' do
        expect(model).to receive(:foreign_key_exists?).with(:projects, name: :foo).and_return(true)

        aggregate_failures do
          expect(model).not_to receive(:concurrent_foreign_key_name)
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/statement_timeout/)
          expect(model).to receive(:execute).ordered.with(/ALTER TABLE projects VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET ALL/)
        end

        model.validate_foreign_key(:projects, :user_id, name: :foo)
      end
    end

    context 'when name is not provided' do
      it 'infers the foreign key constraint name' do
        expect(model).to receive(:foreign_key_exists?).with(:projects, name: anything).and_return(true)

        aggregate_failures do
          expect(model).to receive(:concurrent_foreign_key_name)
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/statement_timeout/)
          expect(model).to receive(:execute).ordered.with(/ALTER TABLE projects VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET ALL/)
        end

        model.validate_foreign_key(:projects, :user_id)
      end

      context 'when the inferred foreign key constraint does not exist' do
        it 'raises an error' do
          expect(model).to receive(:foreign_key_exists?).and_return(false)

          error_message = /Could not find foreign key "fk_name" on table "projects"/
          expect { model.validate_foreign_key(:projects, :user_id, name: :fk_name) }.to raise_error(error_message)
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
  end

  describe '#foreign_key_exists?' do
    before do
      key = ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(:projects, :users, { column: :non_standard_id, name: :fk_projects_users_non_standard_id, on_delete: :cascade })
      allow(model).to receive(:foreign_keys).with(:projects).and_return([key])
    end

    shared_examples_for 'foreign key checks' do
      it 'finds existing foreign keys by column' do
        expect(model.foreign_key_exists?(:projects, target_table, column: :non_standard_id)).to be_truthy
      end

      it 'finds existing foreign keys by name' do
        expect(model.foreign_key_exists?(:projects, target_table, name: :fk_projects_users_non_standard_id)).to be_truthy
      end

      it 'finds existing foreign_keys by name and column' do
        expect(model.foreign_key_exists?(:projects, target_table, name: :fk_projects_users_non_standard_id, column: :non_standard_id)).to be_truthy
      end

      it 'finds existing foreign_keys by name, column and on_delete' do
        expect(model.foreign_key_exists?(:projects, target_table, name: :fk_projects_users_non_standard_id, column: :non_standard_id, on_delete: :cascade)).to be_truthy
      end

      it 'finds existing foreign keys by target table only' do
        expect(model.foreign_key_exists?(:projects, target_table)).to be_truthy
      end

      it 'compares by column name if given' do
        expect(model.foreign_key_exists?(:projects, target_table, column: :user_id)).to be_falsey
      end

      it 'compares by foreign key name if given' do
        expect(model.foreign_key_exists?(:projects, target_table, name: :non_existent_foreign_key_name)).to be_falsey
      end

      it 'compares by foreign key name and column if given' do
        expect(model.foreign_key_exists?(:projects, target_table, name: :non_existent_foreign_key_name, column: :non_standard_id)).to be_falsey
      end

      it 'compares by foreign key name, column and on_delete if given' do
        expect(model.foreign_key_exists?(:projects, target_table, name: :fk_projects_users_non_standard_id, column: :non_standard_id, on_delete: :nullify)).to be_falsey
      end
    end

    context 'without specifying a target table' do
      let(:target_table) { nil }

      it_behaves_like 'foreign key checks'
    end

    context 'specifying a target table' do
      let(:target_table) { :users }

      it_behaves_like 'foreign key checks'
    end

    it 'compares by target table if no column given' do
      expect(model.foreign_key_exists?(:projects, :other_table)).to be_falsey
    end
  end

  describe '#disable_statement_timeout' do
    it 'disables statement timeouts to current transaction only' do
      expect(model).to receive(:execute).with('SET LOCAL statement_timeout TO 0')

      model.disable_statement_timeout
    end

    # this specs runs without an enclosing transaction (:delete truncation method for db_cleaner)
    context 'with real environment', :delete do
      before do
        model.execute("SET statement_timeout TO '20000'")
      end

      after do
        model.execute('RESET ALL')
      end

      it 'defines statement to 0 only for current transaction' do
        expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('20s')

        model.connection.transaction do
          model.disable_statement_timeout
          expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('0')
        end

        expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('20s')
      end

      context 'when passing a blocks' do
        it 'disables statement timeouts on session level and executes the block' do
          expect(model).to receive(:execute).with('SET statement_timeout TO 0')
          expect(model).to receive(:execute).with('RESET ALL').at_least(:once)

          expect { |block| model.disable_statement_timeout(&block) }.to yield_control
        end

        # this specs runs without an enclosing transaction (:delete truncation method for db_cleaner)
        context 'with real environment', :delete do
          before do
            model.execute("SET statement_timeout TO '20000'")
          end

          after do
            model.execute('RESET ALL')
          end

          it 'defines statement to 0 for any code run inside the block' do
            expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('20s')

            model.disable_statement_timeout do
              model.connection.transaction do
                expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('0')
              end

              expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('0')
            end
          end
        end
      end
    end

    # This spec runs without an enclosing transaction (:delete truncation method for db_cleaner)
    context 'when the statement_timeout is already disabled', :delete do
      before do
        ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
      end

      after do
        # Use ActiveRecord::Base.connection instead of model.execute
        # so that this call is not counted below
        ActiveRecord::Base.connection.execute('RESET ALL')
      end

      it 'yields control without disabling the timeout or resetting' do
        expect(model).not_to receive(:execute).with('SET statement_timeout TO 0')
        expect(model).not_to receive(:execute).with('RESET ALL')

        expect { |block| model.disable_statement_timeout(&block) }.to yield_control
      end
    end
  end

  describe '#true_value' do
    it 'returns the appropriate value' do
      expect(model.true_value).to eq("'t'")
    end
  end

  describe '#false_value' do
    it 'returns the appropriate value' do
      expect(model.false_value).to eq("'f'")
    end
  end

  describe '#update_column_in_batches' do
    context 'when running outside of a transaction' do
      before do
        expect(model).to receive(:transaction_open?).and_return(false)

        create_list(:project, 5)
      end

      it 'updates all the rows in a table' do
        model.update_column_in_batches(:projects, :description_html, 'foo')

        expect(Project.where(description_html: 'foo').count).to eq(5)
      end

      it 'updates boolean values correctly' do
        model.update_column_in_batches(:projects, :archived, true)

        expect(Project.where(archived: true).count).to eq(5)
      end

      context 'when a block is supplied' do
        it 'yields an Arel table and query object to the supplied block' do
          first_id = Project.first.id

          model.update_column_in_batches(:projects, :archived, true) do |t, query|
            query.where(t[:id].eq(first_id))
          end

          expect(Project.where(archived: true).count).to eq(1)
        end
      end

      context 'when the value is Arel.sql (Arel::Nodes::SqlLiteral)' do
        it 'updates the value as a SQL expression' do
          model.update_column_in_batches(:projects, :star_count, Arel.sql('1+1'))

          expect(Project.sum(:star_count)).to eq(2 * Project.count)
        end
      end
    end

    context 'when running inside the transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.update_column_in_batches(:projects, :star_count, Arel.sql('1+1'))
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#add_column_with_default' do
    let(:column) { Project.columns.find { |c| c.name == "id" } }

    it 'delegates to #add_column' do
      expect(model).to receive(:add_column).with(:projects, :foo, :integer, default: 10, limit: nil, null: true)

      model.add_column_with_default(:projects, :foo, :integer,
                                    default: 10,
                                    allow_null: true)
    end
  end

  describe '#rename_column_concurrently' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.rename_column_concurrently(:users, :old, :new) }
          .to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:old_column) do
        double(:column,
               type: :integer,
               limit: 8,
               default: 0,
               null: false,
               precision: 5,
               scale: 1)
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :new) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'when the column to rename exists' do
        before do
          allow(model).to receive(:column_for).and_return(old_column)
        end

        it 'renames a column concurrently' do
          expect(model).to receive(:check_trigger_permissions!).with(:users)

          expect(model).to receive(:install_rename_triggers_for_postgresql)
            .with(trigger_name, '"users"', '"old"', '"new"')

          expect(model).to receive(:add_column)
            .with(:users, :new, :integer,
                 limit: old_column.limit,
                 precision: old_column.precision,
                 scale: old_column.scale)

          expect(model).to receive(:change_column_default)
            .with(:users, :new, old_column.default)

          expect(model).to receive(:update_column_in_batches)

          expect(model).to receive(:add_not_null_constraint).with(:users, :new)

          expect(model).to receive(:copy_indexes).with(:users, :old, :new)
          expect(model).to receive(:copy_foreign_keys).with(:users, :old, :new)
          expect(model).to receive(:copy_check_constraints).with(:users, :old, :new)

          model.rename_column_concurrently(:users, :old, :new)
        end

        context 'with existing records and type casting' do
          let(:trigger_name) { model.rename_trigger_name(:users, :id, :new) }
          let(:user) { create(:user) }

          it 'copies the value to the new column using the type_cast_function', :aggregate_failures do
            expect(model).to receive(:copy_indexes).with(:users, :id, :new)
            expect(model).to receive(:add_not_null_constraint).with(:users, :new)
            expect(model).to receive(:execute).with("UPDATE \"users\" SET \"new\" = cast_to_jsonb_with_default(\"users\".\"id\") WHERE \"users\".\"id\" >= #{user.id}")
            expect(model).to receive(:execute).with("DROP TRIGGER IF EXISTS #{trigger_name}\nON \"users\"\n")
            expect(model).to receive(:execute).with("CREATE TRIGGER #{trigger_name}\nBEFORE INSERT OR UPDATE\nON \"users\"\nFOR EACH ROW\nEXECUTE FUNCTION #{trigger_name}()\n")
            expect(model).to receive(:execute).with("CREATE OR REPLACE FUNCTION #{trigger_name}()\nRETURNS trigger AS\n$BODY$\nBEGIN\n  NEW.\"new\" := NEW.\"id\";\n  RETURN NEW;\nEND;\n$BODY$\nLANGUAGE 'plpgsql'\nVOLATILE\n")

            model.rename_column_concurrently(:users, :id, :new, type_cast_function: 'cast_to_jsonb_with_default')
          end
        end

        it 'passes the batch_column_name' do
          expect(model).to receive(:column_exists?).with(:users, :other_batch_column).and_return(true)
          expect(model).to receive(:check_trigger_permissions!).and_return(true)

          expect(model).to receive(:create_column_from).with(
            :users, :old, :new, type: nil, batch_column_name: :other_batch_column, type_cast_function: nil
          ).and_return(true)

          expect(model).to receive(:install_rename_triggers).and_return(true)

          model.rename_column_concurrently(:users, :old, :new, batch_column_name: :other_batch_column)
        end

        it 'passes the type_cast_function' do
          expect(model).to receive(:create_column_from).with(
            :users, :old, :new, type: nil, batch_column_name: :id, type_cast_function: 'JSON'
          ).and_return(true)

          model.rename_column_concurrently(:users, :old, :new, type_cast_function: 'JSON')
        end

        it 'raises an error with invalid batch_column_name' do
          expect do
            model.rename_column_concurrently(:users, :old, :new, batch_column_name: :invalid)
          end.to raise_error(RuntimeError, /Column invalid does not exist on users/)
        end

        context 'when default is false' do
          let(:old_column) do
            double(:column,
                 type: :boolean,
                 limit: nil,
                 default: false,
                 null: false,
                 precision: nil,
                 scale: nil)
          end

          it 'copies the default to the new column' do
            expect(model).to receive(:change_column_default)
              .with(:users, :new, old_column.default)

            expect(model).to receive(:copy_check_constraints)
              .with(:users, :old, :new)

            model.rename_column_concurrently(:users, :old, :new)
          end
        end
      end

      context 'when the column to be renamed does not exist' do
        before do
          allow(model).to receive(:columns).and_return([])
        end

        it 'raises an error with appropriate message' do
          expect(model).to receive(:check_trigger_permissions!).with(:users)

          error_message = /Could not find column "missing_column" on table "users"/
          expect { model.rename_column_concurrently(:users, :missing_column, :new) }.to raise_error(error_message)
        end
      end
    end
  end

  describe '#undo_rename_column_concurrently' do
    it 'reverses the operations of rename_column_concurrently' do
      expect(model).to receive(:check_trigger_permissions!).with(:users)

      expect(model).to receive(:remove_rename_triggers_for_postgresql)
        .with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, :new)

      model.undo_rename_column_concurrently(:users, :old, :new)
    end
  end

  describe '#cleanup_concurrent_column_rename' do
    it 'cleans up the renaming procedure' do
      expect(model).to receive(:check_trigger_permissions!).with(:users)

      expect(model).to receive(:remove_rename_triggers_for_postgresql)
        .with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, :old)

      model.cleanup_concurrent_column_rename(:users, :old, :new)
    end
  end

  describe '#undo_cleanup_concurrent_column_rename' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.undo_cleanup_concurrent_column_rename(:users, :old, :new) }
          .to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:new_column) do
        double(:column,
              type: :integer,
              limit: 8,
              default: 0,
              null: false,
              precision: 5,
              scale: 1)
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :new) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:column_for).and_return(new_column)
      end

      it 'reverses the operations of cleanup_concurrent_column_rename' do
        expect(model).to receive(:check_trigger_permissions!).with(:users)

        expect(model).to receive(:install_rename_triggers_for_postgresql)
          .with(trigger_name, '"users"', '"old"', '"new"')

        expect(model).to receive(:add_column)
          .with(:users, :old, :integer,
              limit: new_column.limit,
              precision: new_column.precision,
              scale: new_column.scale)

        expect(model).to receive(:change_column_default)
          .with(:users, :old, new_column.default)

        expect(model).to receive(:update_column_in_batches)

        expect(model).to receive(:add_not_null_constraint).with(:users, :old)

        expect(model).to receive(:copy_indexes).with(:users, :new, :old)
        expect(model).to receive(:copy_foreign_keys).with(:users, :new, :old)
        expect(model).to receive(:copy_check_constraints).with(:users, :new, :old)

        model.undo_cleanup_concurrent_column_rename(:users, :old, :new)
      end

      it 'passes the batch_column_name' do
        expect(model).to receive(:column_exists?).with(:users, :other_batch_column).and_return(true)
        expect(model).to receive(:check_trigger_permissions!).and_return(true)

        expect(model).to receive(:create_column_from).with(
          :users, :new, :old, type: nil, batch_column_name: :other_batch_column
        ).and_return(true)

        expect(model).to receive(:install_rename_triggers).and_return(true)

        model.undo_cleanup_concurrent_column_rename(:users, :old, :new, batch_column_name: :other_batch_column)
      end

      it 'raises an error with invalid batch_column_name' do
        expect do
          model.undo_cleanup_concurrent_column_rename(:users, :old, :new, batch_column_name: :invalid)
        end.to raise_error(RuntimeError, /Column invalid does not exist on users/)
      end

      context 'when default is false' do
        let(:new_column) do
          double(:column,
               type: :boolean,
               limit: nil,
               default: false,
               null: false,
               precision: nil,
               scale: nil)
        end

        it 'copies the default to the old column' do
          expect(model).to receive(:change_column_default)
            .with(:users, :old, new_column.default)

          expect(model).to receive(:copy_check_constraints)
            .with(:users, :new, :old)

          model.undo_cleanup_concurrent_column_rename(:users, :old, :new)
        end
      end
    end
  end

  describe '#change_column_type_concurrently' do
    it 'changes the column type' do
      expect(model).to receive(:rename_column_concurrently)
        .with('users', 'username', 'username_for_type_change', type: :text, type_cast_function: nil, batch_column_name: :id)

      model.change_column_type_concurrently('users', 'username', :text)
    end

    it 'passed the batch column name' do
      expect(model).to receive(:rename_column_concurrently)
        .with('users', 'username', 'username_for_type_change', type: :text, type_cast_function: nil, batch_column_name: :user_id)

      model.change_column_type_concurrently('users', 'username', :text, batch_column_name: :user_id)
    end

    context 'with type cast' do
      it 'changes the column type with casting the value to the new type' do
        expect(model).to receive(:rename_column_concurrently)
          .with('users', 'username', 'username_for_type_change', type: :text, type_cast_function: 'JSON', batch_column_name: :id)

        model.change_column_type_concurrently('users', 'username', :text, type_cast_function: 'JSON')
      end
    end
  end

  describe '#undo_change_column_type_concurrently' do
    it 'reverses the operations of change_column_type_concurrently' do
      expect(model).to receive(:check_trigger_permissions!).with(:users)

      expect(model).to receive(:remove_rename_triggers_for_postgresql)
        .with(:users, /trigger_.{12}/)

      expect(model).to receive(:remove_column).with(:users, "old_for_type_change")

      model.undo_change_column_type_concurrently(:users, :old)
    end
  end

  describe '#cleanup_concurrent_column_type_change' do
    it 'cleans up the type changing procedure' do
      expect(model).to receive(:cleanup_concurrent_column_rename)
        .with('users', 'username', 'username_for_type_change')

      expect(model).to receive(:rename_column)
        .with('users', 'username_for_type_change', 'username')

      model.cleanup_concurrent_column_type_change('users', 'username')
    end
  end

  describe '#undo_cleanup_concurrent_column_type_change' do
    context 'in a transaction' do
      it 'raises RuntimeError' do
        allow(model).to receive(:transaction_open?).and_return(true)

        expect { model.undo_cleanup_concurrent_column_type_change(:users, :old, :new) }
          .to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      let(:temp_column) { "old_for_type_change" }

      let(:temp_undo_cleanup_column) do
        identifier = "users_old_for_type_change"
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)
        "tmp_undo_cleanup_column_#{hashed_identifier}"
      end

      let(:trigger_name) { model.rename_trigger_name(:users, :old, :old_for_type_change) }

      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      it 'reverses the operations of cleanup_concurrent_column_type_change' do
        expect(model).to receive(:check_trigger_permissions!).with(:users)

        expect(model).to receive(:create_column_from).with(
          :users,
          :old,
          temp_undo_cleanup_column,
          type: :string,
          batch_column_name: :id,
          type_cast_function: nil
        ).and_return(true)

        expect(model).to receive(:rename_column)
          .with(:users, :old, temp_column)

        expect(model).to receive(:rename_column)
          .with(:users, temp_undo_cleanup_column, :old)

        expect(model).to receive(:install_rename_triggers_for_postgresql)
          .with(trigger_name, '"users"', '"old"', '"old_for_type_change"')

        model.undo_cleanup_concurrent_column_type_change(:users, :old, :string)
      end

      it 'passes the type_cast_function and batch_column_name' do
        expect(model).to receive(:column_exists?).with(:users, :other_batch_column).and_return(true)
        expect(model).to receive(:check_trigger_permissions!).with(:users)

        expect(model).to receive(:create_column_from).with(
          :users,
          :old,
          temp_undo_cleanup_column,
          type: :string,
          batch_column_name: :other_batch_column,
          type_cast_function: :custom_type_cast_function
        ).and_return(true)

        expect(model).to receive(:rename_column)
          .with(:users, :old, temp_column)

        expect(model).to receive(:rename_column)
          .with(:users, temp_undo_cleanup_column, :old)

        expect(model).to receive(:install_rename_triggers_for_postgresql)
          .with(trigger_name, '"users"', '"old"', '"old_for_type_change"')

        model.undo_cleanup_concurrent_column_type_change(
          :users,
          :old,
          :string,
          type_cast_function: :custom_type_cast_function,
          batch_column_name: :other_batch_column
        )
      end

      it 'raises an error with invalid batch_column_name' do
        expect do
          model.undo_cleanup_concurrent_column_type_change(:users, :old, :new, batch_column_name: :invalid)
        end.to raise_error(RuntimeError, /Column invalid does not exist on users/)
      end
    end
  end

  describe '#install_rename_triggers_for_postgresql' do
    it 'installs the triggers for PostgreSQL' do
      expect(model).to receive(:execute)
        .with(/CREATE OR REPLACE FUNCTION foo()/m)

      expect(model).to receive(:execute)
        .with(/DROP TRIGGER IF EXISTS foo/m)

      expect(model).to receive(:execute)
        .with(/CREATE TRIGGER foo/m)

      model.install_rename_triggers_for_postgresql('foo', :users, :old, :new)
    end

    it 'does not fail if trigger already exists' do
      model.install_rename_triggers_for_postgresql('foo', :users, :old, :new)
      model.install_rename_triggers_for_postgresql('foo', :users, :old, :new)
    end
  end

  describe '#remove_rename_triggers_for_postgresql' do
    it 'removes the function and trigger' do
      expect(model).to receive(:execute).with('DROP TRIGGER IF EXISTS foo ON bar')
      expect(model).to receive(:execute).with('DROP FUNCTION IF EXISTS foo()')

      model.remove_rename_triggers_for_postgresql('bar', 'foo')
    end
  end

  describe '#rename_trigger_name' do
    it 'returns a String' do
      expect(model.rename_trigger_name(:users, :foo, :bar))
        .to match(/trigger_.{12}/)
    end
  end

  describe '#indexes_for' do
    it 'returns the indexes for a column' do
      idx1 = double(:idx, columns: %w(project_id))
      idx2 = double(:idx, columns: %w(user_id))

      allow(model).to receive(:indexes).with('table').and_return([idx1, idx2])

      expect(model.indexes_for('table', :user_id)).to eq([idx2])
    end
  end

  describe '#foreign_keys_for' do
    it 'returns the foreign keys for a column' do
      fk1 = double(:fk, column: 'project_id')
      fk2 = double(:fk, column: 'user_id')

      allow(model).to receive(:foreign_keys).with('table').and_return([fk1, fk2])

      expect(model.foreign_keys_for('table', :user_id)).to eq([fk2])
    end
  end

  describe '#copy_indexes' do
    context 'using a regular index using a single column' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       using: nil,
                       where: nil,
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [])

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using a regular index with multiple columns' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id foobar),
                       name: 'index_on_issues_project_id_foobar',
                       using: nil,
                       where: nil,
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id foobar),
               unique: false,
               name: 'index_on_issues_gl_project_id_foobar',
               length: [],
               order: [])

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with a WHERE clause' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       using: nil,
                       where: 'foo',
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [],
               where: 'foo')

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with a USING clause' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       where: nil,
                       using: 'foo',
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [],
               using: 'foo')

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with custom operator classes' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_on_issues_project_id',
                       using: nil,
                       where: nil,
                       opclasses: { 'project_id' => 'bar' },
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id),
               unique: false,
               name: 'index_on_issues_gl_project_id',
               length: [],
               order: [],
               opclass: { 'gl_project_id' => 'bar' })

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with multiple columns and custom operator classes' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id foobar),
                       name: 'index_on_issues_project_id_foobar',
                       using: :gin,
                       where: nil,
                       opclasses: { 'project_id' => 'bar', 'foobar' => :gin_trgm_ops },
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id foobar),
               unique: false,
               name: 'index_on_issues_gl_project_id_foobar',
               length: [],
               order: [],
               opclass: { 'gl_project_id' => 'bar', 'foobar' => :gin_trgm_ops },
               using: :gin)

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    context 'using an index with multiple columns and a custom operator class on the non affected column' do
      it 'copies the index' do
        index = double(:index,
                       columns: %w(project_id foobar),
                       name: 'index_on_issues_project_id_foobar',
                       using: :gin,
                       where: nil,
                       opclasses: { 'foobar' => :gin_trgm_ops },
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect(model).to receive(:add_concurrent_index)
          .with(:issues,
               %w(gl_project_id foobar),
               unique: false,
               name: 'index_on_issues_gl_project_id_foobar',
               length: [],
               order: [],
               opclass: { 'foobar' => :gin_trgm_ops },
               using: :gin)

        model.copy_indexes(:issues, :project_id, :gl_project_id)
      end
    end

    describe 'using an index of which the name does not contain the source column' do
      it 'raises RuntimeError' do
        index = double(:index,
                       columns: %w(project_id),
                       name: 'index_foobar_index',
                       using: nil,
                       where: nil,
                       opclasses: {},
                       unique: false,
                       lengths: [],
                       orders: [])

        allow(model).to receive(:indexes_for).with(:issues, 'project_id')
          .and_return([index])

        expect { model.copy_indexes(:issues, :project_id, :gl_project_id) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe '#copy_foreign_keys' do
    it 'copies foreign keys from one column to another' do
      fk = double(:fk,
                  from_table: 'issues',
                  to_table: 'projects',
                  on_delete: :cascade)

      allow(model).to receive(:foreign_keys_for).with(:issues, :project_id)
        .and_return([fk])

      expect(model).to receive(:add_concurrent_foreign_key)
        .with('issues', 'projects', column: :gl_project_id, on_delete: :cascade)

      model.copy_foreign_keys(:issues, :project_id, :gl_project_id)
    end
  end

  describe '#column_for' do
    it 'returns a column object for an existing column' do
      column = model.column_for(:users, :id)

      expect(column.name).to eq('id')
    end

    it 'raises an error when a column does not exist' do
      error_message = /Could not find column "kittens" on table "users"/
      expect { model.column_for(:users, :kittens) }.to raise_error(error_message)
    end
  end

  describe '#replace_sql' do
    it 'builds the sql with correct functions' do
      expect(model.replace_sql(Arel::Table.new(:users)[:first_name], "Alice", "Eve").to_s)
        .to include('regexp_replace')
    end

    describe 'results' do
      let!(:user) { create(:user, name: 'Kathy Alice Aliceson') }

      it 'replaces the correct part of the string' do
        allow(model).to receive(:transaction_open?).and_return(false)
        query = model.replace_sql(Arel::Table.new(:users)[:name], 'Alice', 'Eve')

        model.update_column_in_batches(:users, :name, query)

        expect(user.reload.name).to eq('Kathy Eve Aliceson')
      end
    end
  end

  describe 'sidekiq migration helpers', :redis do
    let(:worker) do
      Class.new do
        include Sidekiq::Worker
        sidekiq_options queue: 'test'
      end
    end

    describe '#sidekiq_queue_length' do
      context 'when queue is empty' do
        it 'returns zero' do
          Sidekiq::Testing.disable! do
            expect(model.sidekiq_queue_length('test')).to eq 0
          end
        end
      end

      context 'when queue contains jobs' do
        it 'returns correct size of the queue' do
          Sidekiq::Testing.disable! do
            worker.perform_async('Something', [1])
            worker.perform_async('Something', [2])

            expect(model.sidekiq_queue_length('test')).to eq 2
          end
        end
      end
    end

    describe '#migrate_sidekiq_queue' do
      it 'migrates jobs from one sidekiq queue to another' do
        Sidekiq::Testing.disable! do
          worker.perform_async('Something', [1])
          worker.perform_async('Something', [2])

          expect(model.sidekiq_queue_length('test')).to eq 2
          expect(model.sidekiq_queue_length('new_test')).to eq 0

          model.sidekiq_queue_migrate('test', to: 'new_test')

          expect(model.sidekiq_queue_length('test')).to eq 0
          expect(model.sidekiq_queue_length('new_test')).to eq 2
        end
      end
    end
  end

  describe '#check_trigger_permissions!' do
    it 'does nothing when the user has the correct permissions' do
      expect { model.check_trigger_permissions!('users') }
        .not_to raise_error
    end

    it 'raises RuntimeError when the user does not have the correct permissions' do
      allow(Gitlab::Database::Grant).to receive(:create_and_execute_trigger?)
        .with('kittens')
        .and_return(false)

      expect { model.check_trigger_permissions!('kittens') }
        .to raise_error(RuntimeError, /Your database user is not allowed/)
    end
  end

  describe '#change_column_type_using_background_migration' do
    let!(:issue) { create(:issue, :closed, closed_at: Time.zone.now) }

    let(:issue_model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'issues'
        include EachBatch
      end
    end

    it 'changes the type of a column using a background migration' do
      expect(model)
        .to receive(:add_column)
        .with('issues', 'closed_at_for_type_change', :datetime_with_timezone)

      expect(model)
        .to receive(:install_rename_triggers)
        .with('issues', :closed_at, 'closed_at_for_type_change')

      expect(BackgroundMigrationWorker)
        .to receive(:perform_in)
        .ordered
        .with(
          10.minutes,
          'CopyColumn',
          ['issues', :closed_at, 'closed_at_for_type_change', issue.id, issue.id]
        )

      expect(BackgroundMigrationWorker)
        .to receive(:perform_in)
        .ordered
        .with(
          1.hour + 10.minutes,
          'CleanupConcurrentTypeChange',
          ['issues', :closed_at, 'closed_at_for_type_change']
        )

      expect(Gitlab::BackgroundMigration)
        .to receive(:steal)
        .ordered
        .with('CopyColumn')

      expect(Gitlab::BackgroundMigration)
        .to receive(:steal)
        .ordered
        .with('CleanupConcurrentTypeChange')

      model.change_column_type_using_background_migration(
        issue_model.all,
        :closed_at,
        :datetime_with_timezone
      )
    end
  end

  describe '#rename_column_using_background_migration' do
    let!(:issue) { create(:issue, :closed, closed_at: Time.zone.now) }

    it 'renames a column using a background migration' do
      expect(model)
        .to receive(:add_column)
        .with(
          'issues',
          :closed_at_timestamp,
          :datetime_with_timezone,
          limit: anything,
          precision: anything,
          scale: anything
        )

      expect(model)
        .to receive(:install_rename_triggers)
        .with('issues', :closed_at, :closed_at_timestamp)

      expect(BackgroundMigrationWorker)
        .to receive(:perform_in)
        .ordered
        .with(
          10.minutes,
          'CopyColumn',
          ['issues', :closed_at, :closed_at_timestamp, issue.id, issue.id]
        )

      expect(BackgroundMigrationWorker)
        .to receive(:perform_in)
        .ordered
        .with(
          1.hour + 10.minutes,
          'CleanupConcurrentRename',
          ['issues', :closed_at, :closed_at_timestamp]
        )

      expect(Gitlab::BackgroundMigration)
        .to receive(:steal)
        .ordered
        .with('CopyColumn')

      expect(Gitlab::BackgroundMigration)
        .to receive(:steal)
        .ordered
        .with('CleanupConcurrentRename')

      model.rename_column_using_background_migration(
        'issues',
        :closed_at,
        :closed_at_timestamp
      )
    end
  end

  describe '#index_exists_by_name?' do
    it 'returns true if an index exists' do
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX test_index_for_index_exists ON projects (path);'
      )

      expect(model.index_exists_by_name?(:projects, 'test_index_for_index_exists'))
        .to be_truthy
    end

    it 'returns false if the index does not exist' do
      expect(model.index_exists_by_name?(:projects, 'this_does_not_exist'))
        .to be_falsy
    end

    context 'when an index with a function exists' do
      before do
        ActiveRecord::Base.connection.execute(
          'CREATE INDEX test_index ON projects (LOWER(path));'
        )
      end

      it 'returns true if an index exists' do
        expect(model.index_exists_by_name?(:projects, 'test_index'))
          .to be_truthy
      end
    end

    context 'when an index exists for a table with the same name in another schema' do
      before do
        ActiveRecord::Base.connection.execute(
          'CREATE SCHEMA new_test_schema'
        )

        ActiveRecord::Base.connection.execute(
          'CREATE TABLE new_test_schema.projects (id integer, name character varying)'
        )

        ActiveRecord::Base.connection.execute(
          'CREATE INDEX test_index_on_name ON new_test_schema.projects (LOWER(name));'
        )
      end

      it 'returns false if the index does not exist in the current schema' do
        expect(model.index_exists_by_name?(:projects, 'test_index_on_name'))
          .to be_falsy
      end
    end
  end

  describe '#create_or_update_plan_limit' do
    before do
      stub_const('Plan', Class.new(ActiveRecord::Base))
      stub_const('PlanLimits', Class.new(ActiveRecord::Base))

      Plan.class_eval do
        self.table_name = 'plans'
      end

      PlanLimits.class_eval do
        self.table_name = 'plan_limits'
      end
    end

    it 'properly escapes names' do
      expect(model).to receive(:execute).with <<~SQL
        INSERT INTO plan_limits (plan_id, "project_hooks")
        SELECT id, '10' FROM plans WHERE name = 'free' LIMIT 1
        ON CONFLICT (plan_id) DO UPDATE SET "project_hooks" = EXCLUDED."project_hooks";
      SQL

      model.create_or_update_plan_limit('project_hooks', 'free', 10)
    end

    context 'when plan does not exist' do
      it 'does not create any plan limits' do
        expect { model.create_or_update_plan_limit('project_hooks', 'plan_name', 10) }
          .not_to change { PlanLimits.count }
      end
    end

    context 'when plan does exist' do
      let!(:plan) { Plan.create!(name: 'plan_name') }

      context 'when limit does not exist' do
        it 'inserts a new plan limits' do
          expect { model.create_or_update_plan_limit('project_hooks', 'plan_name', 10) }
            .to change { PlanLimits.count }.by(1)

          expect(PlanLimits.pluck(:project_hooks)).to contain_exactly(10)
        end
      end

      context 'when limit does exist' do
        let!(:plan_limit) { PlanLimits.create!(plan_id: plan.id) }

        it 'updates an existing plan limits' do
          expect { model.create_or_update_plan_limit('project_hooks', 'plan_name', 999) }
            .not_to change { PlanLimits.count }

          expect(plan_limit.reload.project_hooks).to eq(999)
        end
      end
    end
  end

  describe '#with_lock_retries' do
    let(:buffer) { StringIO.new }
    let(:in_memory_logger) { Gitlab::JsonLogger.new(buffer) }
    let(:env) { { 'DISABLE_LOCK_RETRIES' => 'true' } }

    it 'sets the migration class name in the logs' do
      model.with_lock_retries(env: env, logger: in_memory_logger) { }

      buffer.rewind
      expect(buffer.read).to include("\"class\":\"#{model.class}\"")
    end
  end

  describe '#backfill_iids' do
    include MigrationsHelpers

    before do
      stub_const('Issue', Class.new(ActiveRecord::Base))

      Issue.class_eval do
        include AtomicInternalId

        self.table_name = 'issues'
        self.inheritance_column = :_type_disabled

        belongs_to :project, class_name: "::Project"

        has_internal_id :iid,
          scope: :project,
          init: ->(s, _scope) { s&.project&.issues&.maximum(:iid) },
          backfill: true,
          presence: false
      end
    end

    let(:namespaces)     { table(:namespaces) }
    let(:projects)       { table(:projects) }
    let(:issues)         { table(:issues) }

    def setup
      namespace = namespaces.create!(name: 'foo', path: 'foo')
      project = projects.create!(namespace_id: namespace.id)

      project
    end

    it 'generates iids properly for models created after the migration' do
      project = setup

      model.backfill_iids('issues')

      issue = Issue.create!(project_id: project.id)

      expect(issue.iid).to eq(1)
    end

    it 'generates iids properly for models created after the migration when iids are backfilled' do
      project = setup
      issue_a = issues.create!(project_id: project.id)

      model.backfill_iids('issues')

      issue_b = Issue.create!(project_id: project.id)

      expect(issue_a.reload.iid).to eq(1)
      expect(issue_b.iid).to eq(2)
    end

    it 'generates iids properly for models created after the migration across multiple projects' do
      project_a = setup
      project_b = setup
      issues.create!(project_id: project_a.id)
      issues.create!(project_id: project_b.id)
      issues.create!(project_id: project_b.id)

      model.backfill_iids('issues')

      issue_a = Issue.create!(project_id: project_a.id)
      issue_b = Issue.create!(project_id: project_b.id)

      expect(issue_a.iid).to eq(2)
      expect(issue_b.iid).to eq(3)
    end

    context 'when the new code creates a row post deploy but before the migration runs' do
      it 'does not change the row iid' do
        project = setup
        issue = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        expect(issue.reload.iid).to eq(1)
      end

      it 'backfills iids for rows already in the database' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_c.reload.iid).to eq(3)
      end

      it 'backfills iids across multiple projects' do
        project_a = setup
        project_b = setup
        issue_a = issues.create!(project_id: project_a.id)
        issue_b = issues.create!(project_id: project_b.id)
        issue_c = Issue.create!(project_id: project_a.id)
        issue_d = Issue.create!(project_id: project_b.id)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(1)
        expect(issue_c.reload.iid).to eq(2)
        expect(issue_d.reload.iid).to eq(2)
      end

      it 'generates iids properly for models created after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        issue_d = Issue.create!(project_id: project.id)
        issue_e = Issue.create!(project_id: project.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_c.reload.iid).to eq(3)
        expect(issue_d.iid).to eq(4)
        expect(issue_e.iid).to eq(5)
      end

      it 'backfills iids and properly generates iids for new models across multiple projects' do
        project_a = setup
        project_b = setup
        issue_a = issues.create!(project_id: project_a.id)
        issue_b = issues.create!(project_id: project_b.id)
        issue_c = Issue.create!(project_id: project_a.id)
        issue_d = Issue.create!(project_id: project_b.id)

        model.backfill_iids('issues')

        issue_e = Issue.create!(project_id: project_a.id)
        issue_f = Issue.create!(project_id: project_b.id)
        issue_g = Issue.create!(project_id: project_a.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(1)
        expect(issue_c.reload.iid).to eq(2)
        expect(issue_d.reload.iid).to eq(2)
        expect(issue_e.iid).to eq(3)
        expect(issue_f.iid).to eq(3)
        expect(issue_g.iid).to eq(4)
      end
    end

    context 'when the new code creates a model and then old code creates a model post deploy but before the migration runs' do
      it 'backfills iids' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = Issue.create!(project_id: project.id)
        issue_c = issues.create!(project_id: project.id)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_c.reload.iid).to eq(3)
      end

      it 'generates an iid for a new model after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_d = issues.create!(project_id: project.id)

        model.backfill_iids('issues')

        issue_e = Issue.create!(project_id: project.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_c.reload.iid).to eq(3)
        expect(issue_d.reload.iid).to eq(4)
        expect(issue_e.iid).to eq(5)
      end
    end

    context 'when the new code and old code alternate creating models post deploy but before the migration runs' do
      it 'backfills iids' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = Issue.create!(project_id: project.id)
        issue_c = issues.create!(project_id: project.id)
        issue_d = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_c.reload.iid).to eq(3)
        expect(issue_d.reload.iid).to eq(4)
      end

      it 'generates an iid for a new model after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_d = issues.create!(project_id: project.id)
        issue_e = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        issue_f = Issue.create!(project_id: project.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_c.reload.iid).to eq(3)
        expect(issue_d.reload.iid).to eq(4)
        expect(issue_e.reload.iid).to eq(5)
        expect(issue_f.iid).to eq(6)
      end
    end

    context 'when the new code creates and deletes a model post deploy but before the migration runs' do
      it 'backfills iids for rows already in the database' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_c.delete

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
      end

      it 'successfully creates a new model after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_c.delete

        model.backfill_iids('issues')

        issue_d = Issue.create!(project_id: project.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_d.iid).to eq(3)
      end
    end

    context 'when the new code creates and deletes a model and old code creates a model post deploy but before the migration runs' do
      it 'backfills iids' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_c.delete
        issue_d = issues.create!(project_id: project.id)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_d.reload.iid).to eq(3)
      end

      it 'successfully creates a new model after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_c.delete
        issue_d = issues.create!(project_id: project.id)

        model.backfill_iids('issues')

        issue_e = Issue.create!(project_id: project.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_d.reload.iid).to eq(3)
        expect(issue_e.iid).to eq(4)
      end
    end

    context 'when the new code creates and deletes a model and then creates another model post deploy but before the migration runs' do
      it 'successfully generates an iid for a new model after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_c.delete
        issue_d = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_d.reload.iid).to eq(3)
      end

      it 'successfully generates an iid for a new model after the migration' do
        project = setup
        issue_a = issues.create!(project_id: project.id)
        issue_b = issues.create!(project_id: project.id)
        issue_c = Issue.create!(project_id: project.id)
        issue_c.delete
        issue_d = Issue.create!(project_id: project.id)

        model.backfill_iids('issues')

        issue_e = Issue.create!(project_id: project.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
        expect(issue_d.reload.iid).to eq(3)
        expect(issue_e.iid).to eq(4)
      end
    end

    context 'when the first model is created for a project after the migration' do
      it 'generates an iid' do
        project_a = setup
        project_b = setup
        issue_a = issues.create!(project_id: project_a.id)

        model.backfill_iids('issues')

        issue_b = Issue.create!(project_id: project_b.id)

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(1)
      end
    end

    context 'when a row already has an iid set in the database' do
      it 'backfills iids' do
        project = setup
        issue_a = issues.create!(project_id: project.id, iid: 1)
        issue_b = issues.create!(project_id: project.id, iid: 2)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(2)
      end

      it 'backfills for multiple projects' do
        project_a = setup
        project_b = setup
        issue_a = issues.create!(project_id: project_a.id, iid: 1)
        issue_b = issues.create!(project_id: project_b.id, iid: 1)
        issue_c = issues.create!(project_id: project_a.id, iid: 2)

        model.backfill_iids('issues')

        expect(issue_a.reload.iid).to eq(1)
        expect(issue_b.reload.iid).to eq(1)
        expect(issue_c.reload.iid).to eq(2)
      end
    end
  end

  describe '#check_constraint_name' do
    it 'returns a valid constraint name' do
      name = model.check_constraint_name(:this_is_a_very_long_table_name,
                                         :with_a_very_long_column_name,
                                         :with_a_very_long_type)

      expect(name).to be_an_instance_of(String)
      expect(name).to start_with('check_')
      expect(name.length).to eq(16)
    end
  end

  describe '#check_constraint_exists?' do
    before do
      ActiveRecord::Base.connection.execute(
        'ALTER TABLE projects ADD CONSTRAINT check_1 CHECK (char_length(path) <= 5) NOT VALID'
      )

      ActiveRecord::Base.connection.execute(
        'CREATE SCHEMA new_test_schema'
      )

      ActiveRecord::Base.connection.execute(
        'CREATE TABLE new_test_schema.projects (id integer, name character varying)'
      )

      ActiveRecord::Base.connection.execute(
        'ALTER TABLE new_test_schema.projects ADD CONSTRAINT check_2 CHECK (char_length(name) <= 5)'
      )
    end

    it 'returns true if a constraint exists' do
      expect(model.check_constraint_exists?(:projects, 'check_1'))
        .to be_truthy
    end

    it 'returns false if a constraint does not exist' do
      expect(model.check_constraint_exists?(:projects, 'this_does_not_exist'))
        .to be_falsy
    end

    it 'returns false if a constraint with the same name exists in another table' do
      expect(model.check_constraint_exists?(:users, 'check_1'))
        .to be_falsy
    end

    it 'returns false if a constraint with the same name exists for the same table in another schema' do
      expect(model.check_constraint_exists?(:projects, 'check_2'))
        .to be_falsy
    end
  end

  describe '#add_check_constraint' do
    before do
      allow(model).to receive(:check_constraint_exists?).and_return(false)
    end

    context 'constraint name validation' do
      it 'raises an error when too long' do
        expect do
          model.add_check_constraint(
            :test_table,
            'name IS NOT NULL',
            'a' * (Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH + 1)
          )
        end.to raise_error(RuntimeError)
      end

      it 'does not raise error when the length is acceptable' do
        constraint_name = 'a' * Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH

        expect(model).to receive(:transaction_open?).and_return(false)
        expect(model).to receive(:check_constraint_exists?).and_return(false)
        expect(model).to receive(:with_lock_retries).and_call_original
        expect(model).to receive(:execute).with(/ADD CONSTRAINT/)

        model.add_check_constraint(
          :test_table,
          'name IS NOT NULL',
          constraint_name,
          validate: false
        )
      end
    end

    context 'inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_check_constraint(
            :test_table,
            'name IS NOT NULL',
            'check_name_not_null'
          )
        end.to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'when the constraint is already defined in the database' do
        it 'does not create a constraint' do
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(true)

          expect(model).not_to receive(:execute).with(/ADD CONSTRAINT/)

          # setting validate: false to only focus on the ADD CONSTRAINT command
          model.add_check_constraint(
            :test_table,
            'name IS NOT NULL',
            'check_name_not_null',
            validate: false
          )
        end
      end

      context 'when the constraint is not defined in the database' do
        it 'creates the constraint' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT check_name_not_null/)

          # setting validate: false to only focus on the ADD CONSTRAINT command
          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null',
            validate: false
          )
        end
      end

      context 'when validate is not provided' do
        it 'performs validation' do
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(false).exactly(1)

          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/statement_timeout/)
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT check_name_not_null/)

          # we need the check constraint to exist so that the validation proceeds
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(true).exactly(1)

          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET ALL/)

          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null'
          )
        end
      end

      context 'when validate is provided with a falsey value' do
        it 'skips validation' do
          expect(model).not_to receive(:disable_statement_timeout)
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT/)
          expect(model).not_to receive(:execute).with(/VALIDATE CONSTRAINT/)

          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null',
            validate: false
          )
        end
      end

      context 'when validate is provided with a truthy value' do
        it 'performs validation' do
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(false).exactly(1)

          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/statement_timeout/)
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT check_name_not_null/)

          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(true).exactly(1)

          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET ALL/)

          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null',
            validate: true
          )
        end
      end
    end
  end

  describe '#validate_check_constraint' do
    context 'when the constraint does not exist' do
      it 'raises an error' do
        error_message = /Could not find check constraint "check_1" on table "test_table"/

        expect(model).to receive(:check_constraint_exists?).and_return(false)

        expect do
          model.validate_check_constraint(:test_table, 'check_1')
        end.to raise_error(RuntimeError, error_message)
      end
    end

    context 'when the constraint exists' do
      it 'performs validation' do
        validate_sql = /ALTER TABLE test_table VALIDATE CONSTRAINT check_name/

        expect(model).to receive(:check_constraint_exists?).and_return(true)
        expect(model).to receive(:disable_statement_timeout).and_call_original
        expect(model).to receive(:statement_timeout_disabled?).and_return(false)
        expect(model).to receive(:execute).with(/statement_timeout/)
        expect(model).to receive(:execute).ordered.with(validate_sql)
        expect(model).to receive(:execute).ordered.with(/RESET ALL/)

        model.validate_check_constraint(:test_table, 'check_name')
      end
    end
  end

  describe '#remove_check_constraint' do
    it 'removes the constraint' do
      drop_sql = /ALTER TABLE test_table\s+DROP CONSTRAINT IF EXISTS check_name/

      expect(model).to receive(:with_lock_retries).and_call_original
      expect(model).to receive(:execute).with(drop_sql)

      model.remove_check_constraint(:test_table, 'check_name')
    end
  end

  describe '#copy_check_constraints' do
    context 'inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.copy_check_constraints(:test_table, :old_column, :new_column)
        end.to raise_error(RuntimeError)
      end
    end

    context 'outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:column_exists?).and_return(true)
      end

      let(:old_column_constraints) do
        [
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'check_d7d49d475d',
            'constraint_def' => 'CHECK ((old_column IS NOT NULL))'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'check_48560e521e',
            'constraint_def' => 'CHECK ((char_length(old_column) <= 255))'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'custom_check_constraint',
            'constraint_def' => 'CHECK (((old_column IS NOT NULL) AND (another_column IS NULL)))'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'not_valid_check_constraint',
            'constraint_def' => 'CHECK ((old_column IS NOT NULL)) NOT VALID'
          }
        ]
      end

      it 'copies check constraints from one column to another' do
        allow(model).to receive(:check_constraints_for)
        .with(:test_table, :old_column, schema: nil)
          .and_return(old_column_constraints)

        allow(model).to receive(:not_null_constraint_name).with(:test_table, :new_column)
          .and_return('check_1')

        allow(model).to receive(:text_limit_name).with(:test_table, :new_column)
          .and_return('check_2')

        allow(model).to receive(:check_constraint_name)
          .with(:test_table, :new_column, 'copy_check_constraint')
          .and_return('check_3')

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '(new_column IS NOT NULL)',
            'check_1',
            validate: true
          ).once

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '(char_length(new_column) <= 255)',
            'check_2',
            validate: true
          ).once

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '((new_column IS NOT NULL) AND (another_column IS NULL))',
            'check_3',
            validate: true
          ).once

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '(new_column IS NOT NULL)',
            'check_1',
            validate: false
          ).once

        model.copy_check_constraints(:test_table, :old_column, :new_column)
      end

      it 'does nothing if there are no constraints defined for the old column' do
        allow(model).to receive(:check_constraints_for)
        .with(:test_table, :old_column, schema: nil)
          .and_return([])

        expect(model).not_to receive(:add_check_constraint)

        model.copy_check_constraints(:test_table, :old_column, :new_column)
      end

      it 'raises an error when the orginating column does not exist' do
        allow(model).to receive(:column_exists?).with(:test_table, :old_column).and_return(false)

        error_message = /Column old_column does not exist on test_table/

        expect do
          model.copy_check_constraints(:test_table, :old_column, :new_column)
        end.to raise_error(RuntimeError, error_message)
      end

      it 'raises an error when the target column does not exist' do
        allow(model).to receive(:column_exists?).with(:test_table, :new_column).and_return(false)

        error_message = /Column new_column does not exist on test_table/

        expect do
          model.copy_check_constraints(:test_table, :old_column, :new_column)
        end.to raise_error(RuntimeError, error_message)
      end
    end
  end

  describe '#add_text_limit' do
    context 'when it is called with the default options' do
      it 'calls add_check_constraint with an infered constraint name and validate: true' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'max_length')
        check = "char_length(name) <= 255"

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: true)

        model.add_text_limit(:test_table, :name, 255)
      end
    end

    context 'when all parameters are provided' do
      it 'calls add_check_constraint with the correct parameters' do
        constraint_name = 'check_name_limit'
        check = "char_length(name) <= 255"

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: false)

        model.add_text_limit(
          :test_table,
          :name,
          255,
          constraint_name: constraint_name,
          validate: false
        )
      end
    end
  end

  describe '#validate_text_limit' do
    context 'when constraint_name is not provided' do
      it 'calls validate_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'max_length')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_text_limit(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls validate_check_constraint with the correct parameters' do
        constraint_name = 'check_name_limit'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_text_limit(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#remove_text_limit' do
    context 'when constraint_name is not provided' do
      it 'calls remove_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'max_length')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_text_limit(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls remove_check_constraint with the correct parameters' do
        constraint_name = 'check_name_limit'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_text_limit(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#check_text_limit_exists?' do
    context 'when constraint_name is not provided' do
      it 'calls check_constraint_exists? with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'max_length')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_text_limit_exists?(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls check_constraint_exists? with the correct parameters' do
        constraint_name = 'check_name_limit'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_text_limit_exists?(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#add_not_null_constraint' do
    context 'when it is called with the default options' do
      it 'calls add_check_constraint with an infered constraint name and validate: true' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'not_null')
        check = "name IS NOT NULL"

        expect(model).to receive(:column_is_nullable?).and_return(true)
        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: true)

        model.add_not_null_constraint(:test_table, :name)
      end
    end

    context 'when all parameters are provided' do
      it 'calls add_check_constraint with the correct parameters' do
        constraint_name = 'check_name_not_null'
        check = "name IS NOT NULL"

        expect(model).to receive(:column_is_nullable?).and_return(true)
        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: false)

        model.add_not_null_constraint(
          :test_table,
          :name,
          constraint_name: constraint_name,
          validate: false
        )
      end
    end

    context 'when the column is defined as NOT NULL' do
      it 'does not add a check constraint' do
        expect(model).to receive(:column_is_nullable?).and_return(false)
        expect(model).not_to receive(:check_constraint_name)
        expect(model).not_to receive(:add_check_constraint)

        model.add_not_null_constraint(:test_table, :name)
      end
    end
  end

  describe '#validate_not_null_constraint' do
    context 'when constraint_name is not provided' do
      it 'calls validate_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'not_null')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_not_null_constraint(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls validate_check_constraint with the correct parameters' do
        constraint_name = 'check_name_not_null'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_not_null_constraint(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#remove_not_null_constraint' do
    context 'when constraint_name is not provided' do
      it 'calls remove_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'not_null')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_not_null_constraint(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls remove_check_constraint with the correct parameters' do
        constraint_name = 'check_name_not_null'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_not_null_constraint(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#check_not_null_constraint_exists?' do
    context 'when constraint_name is not provided' do
      it 'calls check_constraint_exists? with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table,
                                                      :name,
                                                      'not_null')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_not_null_constraint_exists?(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls check_constraint_exists? with the correct parameters' do
        constraint_name = 'check_name_not_null'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_not_null_constraint_exists?(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#create_extension' do
    subject { model.create_extension(extension) }

    let(:extension) { :btree_gist }

    it 'executes CREATE EXTENSION statement' do
      expect(model).to receive(:execute).with(/CREATE EXTENSION IF NOT EXISTS #{extension}/)

      subject
    end

    context 'without proper permissions' do
      before do
        allow(model).to receive(:execute).with(/CREATE EXTENSION IF NOT EXISTS #{extension}/).and_raise(ActiveRecord::StatementInvalid, 'InsufficientPrivilege: permission denied')
      end

      it 'raises the exception' do
        expect { subject }.to raise_error(ActiveRecord::StatementInvalid, /InsufficientPrivilege/)
      end

      it 'prints an error message' do
        expect { subject }.to output(/user is not allowed/).to_stderr.and raise_error
      end
    end
  end

  describe '#drop_extension' do
    subject { model.drop_extension(extension) }

    let(:extension) { 'btree_gist' }

    it 'executes CREATE EXTENSION statement' do
      expect(model).to receive(:execute).with(/DROP EXTENSION IF EXISTS #{extension}/)

      subject
    end

    context 'without proper permissions' do
      before do
        allow(model).to receive(:execute).with(/DROP EXTENSION IF EXISTS #{extension}/).and_raise(ActiveRecord::StatementInvalid, 'InsufficientPrivilege: permission denied')
      end

      it 'raises the exception' do
        expect { subject }.to raise_error(ActiveRecord::StatementInvalid, /InsufficientPrivilege/)
      end

      it 'prints an error message' do
        expect { subject }.to output(/user is not allowed/).to_stderr.and raise_error
      end
    end
  end
end
