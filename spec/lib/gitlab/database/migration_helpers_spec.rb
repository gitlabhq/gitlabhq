# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::MigrationHelpers do
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
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).with(/RESET ALL/)

            expect(model).to receive(:execute).with(/ON DELETE SET NULL/)

            model.add_concurrent_foreign_key(:projects, :users,
                                             column: :user_id,
                                             on_delete: :nullify)
          end
        end

        context 'on_delete: :cascade' do
          it 'appends ON DELETE CASCADE statement' do
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).with(/RESET ALL/)

            expect(model).to receive(:execute).with(/ON DELETE CASCADE/)

            model.add_concurrent_foreign_key(:projects, :users,
                                             column: :user_id,
                                             on_delete: :cascade)
          end
        end

        context 'on_delete: nil' do
          it 'appends no ON DELETE statement' do
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
            expect(model).to receive(:execute).with(/RESET ALL/)

            expect(model).not_to receive(:execute).with(/ON DELETE/)

            model.add_concurrent_foreign_key(:projects, :users,
                                             column: :user_id,
                                             on_delete: nil)
          end
        end
      end

      context 'when no custom key name is supplied' do
        it 'creates a concurrent foreign key and validates it' do
          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:execute).with(/statement_timeout/)
          expect(model).to receive(:execute).ordered.with(/NOT VALID/)
          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).with(/RESET ALL/)

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
            expect(model).to receive(:disable_statement_timeout).and_call_original
            expect(model).to receive(:execute).with(/statement_timeout/)
            expect(model).to receive(:execute).ordered.with(/NOT VALID/)
            expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+foo/)
            expect(model).to receive(:execute).with(/RESET ALL/)

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
              expect(model).to receive(:disable_statement_timeout).and_call_original
              expect(model).to receive(:execute).with(/statement_timeout/)
              expect(model).to receive(:execute).ordered.with(/NOT VALID/)
              expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT.+bar/)
              expect(model).to receive(:execute).with(/RESET ALL/)

              model.add_concurrent_foreign_key(:projects, :users, column: :user_id, name: :bar)
            end
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
    context 'outside of a transaction' do
      context 'when a column limit is not set' do
        before do
          expect(model).to receive(:transaction_open?)
            .and_return(false)
            .at_least(:once)

          expect(model).to receive(:transaction).and_yield

          expect(model).to receive(:add_column)
            .with(:projects, :foo, :integer, default: nil)

          expect(model).to receive(:change_column_default)
            .with(:projects, :foo, 10)
        end

        it 'adds the column while allowing NULL values' do
          expect(model).to receive(:update_column_in_batches)
            .with(:projects, :foo, 10)

          expect(model).not_to receive(:change_column_null)

          model.add_column_with_default(:projects, :foo, :integer,
                                        default: 10,
                                        allow_null: true)
        end

        it 'adds the column while not allowing NULL values' do
          expect(model).to receive(:update_column_in_batches)
            .with(:projects, :foo, 10)

          expect(model).to receive(:change_column_null)
            .with(:projects, :foo, false)

          model.add_column_with_default(:projects, :foo, :integer, default: 10)
        end

        it 'removes the added column whenever updating the rows fails' do
          expect(model).to receive(:update_column_in_batches)
            .with(:projects, :foo, 10)
            .and_raise(RuntimeError)

          expect(model).to receive(:remove_column)
            .with(:projects, :foo)

          expect do
            model.add_column_with_default(:projects, :foo, :integer, default: 10)
          end.to raise_error(RuntimeError)
        end

        it 'removes the added column whenever changing a column NULL constraint fails' do
          expect(model).to receive(:change_column_null)
            .with(:projects, :foo, false)
            .and_raise(RuntimeError)

          expect(model).to receive(:remove_column)
            .with(:projects, :foo)

          expect do
            model.add_column_with_default(:projects, :foo, :integer, default: 10)
          end.to raise_error(RuntimeError)
        end
      end

      context 'when a column limit is set' do
        it 'adds the column with a limit' do
          allow(model).to receive(:transaction_open?).and_return(false)
          allow(model).to receive(:transaction).and_yield
          allow(model).to receive(:update_column_in_batches).with(:projects, :foo, 10)
          allow(model).to receive(:change_column_null).with(:projects, :foo, false)
          allow(model).to receive(:change_column_default).with(:projects, :foo, 10)

          expect(model).to receive(:add_column)
            .with(:projects, :foo, :integer, default: nil, limit: 8)

          model.add_column_with_default(:projects, :foo, :integer, default: 10, limit: 8)
        end
      end

      it 'adds a column with an array default value for a jsonb type' do
        create(:project)
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:transaction).and_yield
        expect(model).to receive(:update_column_in_batches).with(:projects, :foo, '[{"foo":"json"}]').and_call_original

        model.add_column_with_default(:projects, :foo, :jsonb, default: [{ foo: "json" }])
      end

      it 'adds a column with an object default value for a jsonb type' do
        create(:project)
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:transaction).and_yield
        expect(model).to receive(:update_column_in_batches).with(:projects, :foo, '{"foo":"json"}').and_call_original

        model.add_column_with_default(:projects, :foo, :jsonb, default: { foo: "json" })
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_column_with_default(:projects, :foo, :integer, default: 10)
        end.to raise_error(RuntimeError)
      end
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

        expect(model).to receive(:change_column_null).with(:users, :new, false)

        expect(model).to receive(:copy_indexes).with(:users, :old, :new)
        expect(model).to receive(:copy_foreign_keys).with(:users, :old, :new)

        model.rename_column_concurrently(:users, :old, :new)
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

          model.rename_column_concurrently(:users, :old, :new)
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

        expect(model).to receive(:change_column_null).with(:users, :old, false)

        expect(model).to receive(:copy_indexes).with(:users, :new, :old)
        expect(model).to receive(:copy_foreign_keys).with(:users, :new, :old)

        model.undo_cleanup_concurrent_column_rename(:users, :old, :new)
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

          model.undo_cleanup_concurrent_column_rename(:users, :old, :new)
        end
      end
    end
  end

  describe '#change_column_type_concurrently' do
    it 'changes the column type' do
      expect(model).to receive(:rename_column_concurrently)
        .with('users', 'username', 'username_for_type_change', type: :text)

      model.change_column_type_concurrently('users', 'username', :text)
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
               opclasses: { 'gl_project_id' => 'bar' })

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

    it 'returns nil when a column does not exist' do
      expect(model.column_for(:users, :kittens)).to be_nil
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

  describe 'sidekiq migration helpers', :sidekiq, :redis do
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

  describe '#bulk_queue_background_migration_jobs_by_range', :sidekiq do
    context 'when the model has an ID column' do
      let!(:id1) { create(:user).id }
      let!(:id2) { create(:user).id }
      let!(:id3) { create(:user).id }

      before do
        User.class_eval do
          include EachBatch
        end
      end

      context 'with enough rows to bulk queue jobs more than once' do
        before do
          stub_const('Gitlab::Database::MigrationHelpers::BACKGROUND_MIGRATION_JOB_BUFFER_SIZE', 1)
        end

        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
          end
        end

        it 'queues jobs in groups of buffer size 1' do
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['FooJob', [id1, id2]]])
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['FooJob', [id3, id3]]])

          model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)
        end
      end

      context 'with not enough rows to bulk queue jobs more than once' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
          end
        end

        it 'queues jobs in bulk all at once (big buffer size)' do
          expect(BackgroundMigrationWorker).to receive(:bulk_perform_async).with([['FooJob', [id1, id2]],
                                                                                  ['FooJob', [id3, id3]]])

          model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob', batch_size: 2)
        end
      end

      context 'without specifying batch_size' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.bulk_queue_background_migration_jobs_by_range(User, 'FooJob')

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id3]])
          end
        end
      end
    end

    context "when the model doesn't have an ID column" do
      it 'raises error (for now)' do
        expect do
          model.bulk_queue_background_migration_jobs_by_range(ProjectAuthorization, 'FooJob')
        end.to raise_error(StandardError, /does not have an ID/)
      end
    end
  end

  describe '#queue_background_migration_jobs_by_range_at_intervals', :sidekiq do
    context 'when the model has an ID column' do
      let!(:id1) { create(:user).id }
      let!(:id2) { create(:user).id }
      let!(:id3) { create(:user).id }

      around do |example|
        Timecop.freeze { example.run }
      end

      before do
        User.class_eval do
          include EachBatch
        end
      end

      context 'with batch_size option' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes, batch_size: 2)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id2]])
            expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
            expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['FooJob', [id3, id3]])
            expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(20.minutes.from_now.to_f)
          end
        end
      end

      context 'without batch_size option' do
        it 'queues jobs correctly' do
          Sidekiq::Testing.fake! do
            model.queue_background_migration_jobs_by_range_at_intervals(User, 'FooJob', 10.minutes)

            expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['FooJob', [id1, id3]])
            expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(10.minutes.from_now.to_f)
          end
        end
      end
    end

    context "when the model doesn't have an ID column" do
      it 'raises error (for now)' do
        expect do
          model.queue_background_migration_jobs_by_range_at_intervals(ProjectAuthorization, 'FooJob', 10.seconds)
        end.to raise_error(StandardError, /does not have an ID/)
      end
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

  describe '#perform_background_migration_inline?' do
    it 'returns true in a test environment' do
      stub_rails_env('test')

      expect(model.perform_background_migration_inline?).to eq(true)
    end

    it 'returns true in a development environment' do
      stub_rails_env('development')

      expect(model.perform_background_migration_inline?).to eq(true)
    end

    it 'returns false in a production environment' do
      stub_rails_env('production')

      expect(model.perform_background_migration_inline?).to eq(false)
    end
  end

  describe '#index_exists_by_name?' do
    it 'returns true if an index exists' do
      expect(model.index_exists_by_name?(:projects, 'index_projects_on_path'))
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

      after do
        'DROP INDEX IF EXISTS test_index;'
      end

      it 'returns true if an index exists' do
        expect(model.index_exists_by_name?(:projects, 'test_index'))
          .to be_truthy
      end
    end
  end
end
