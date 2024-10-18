# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Triggers::AssignDesiredShardingKey, feature_category: :database do
  include Database::TriggerHelpers

  let(:table_name) { :_test_table }
  let(:connection) { ActiveRecord::Base.connection }
  let(:trigger) { described_class.new(**attributes) }
  let(:trigger_name) { trigger.name }
  let(:parent_table_pk) { nil }

  let(:attributes) do
    {
      table: table_name,
      sharding_key: :project_id,
      parent_table: :_test_project_parent,
      parent_table_primary_key: parent_table_pk,
      parent_sharding_key: :parent_project_id,
      foreign_key: :project_fk_id,
      connection: connection
    }
  end

  before do
    connection.schema_cache.clear!
  end

  describe '#create' do
    let(:model) { Class.new(ActiveRecord::Base) }

    let(:valid_project_parent_id) { 10 }
    let(:valid_project_parent_sharding_key) { 20 }
    let(:invalid_project_parent_id) { 60 }

    subject(:create_trigger) { trigger.create } # rubocop: disable Rails/SaveBang -- Not an ActiveRecord model

    before do
      connection.execute(<<~SQL)
        CREATE TABLE _test_project_parent (
          id serial NOT NULL PRIMARY KEY,
          parent_project_id bigint);

        CREATE TABLE #{table_name} (
          id serial NOT NULL PRIMARY KEY,
          project_fk_id bigint,
          project_id bigint);

        INSERT INTO _test_project_parent (id, parent_project_id) VALUES
          (#{valid_project_parent_id}, #{valid_project_parent_sharding_key}),
          (#{invalid_project_parent_id}, NULL);
      SQL

      model.table_name = table_name
    end

    it 'creates the trigger and function' do
      expect_function_not_to_exist(trigger_name)
      expect_trigger_not_to_exist(table_name, trigger_name)

      create_trigger

      expect_function_to_exist(trigger_name)
      expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
    end

    it 'assigns the sharding key using the trigger function' do
      create_trigger

      record = model.create!(project_fk_id: valid_project_parent_id)
      expect(record.reload).to have_attributes(project_id: valid_project_parent_sharding_key)
    end

    context 'when the sharding key is already set' do
      it 'does not change the sharding key' do
        create_trigger

        record = model.create!(project_fk_id: valid_project_parent_id, project_id: 99)
        expect(record.reload).to have_attributes(project_id: 99)
      end
    end

    context 'when no matching record is found' do
      it 'does not set the sharding key' do
        create_trigger

        record = model.create!(project_fk_id: non_existing_record_id)
        expect(record.reload).to have_attributes(project_id: nil)
      end
    end

    context 'when a matching record is found but the sharding key is missing' do
      it 'does not set the sharding key' do
        create_trigger

        record = model.create!(project_fk_id: invalid_project_parent_id)
        expect(record.reload).to have_attributes(project_id: nil)
      end
    end

    context 'when a custom trigger name is supplied' do
      let(:trigger) { described_class.new(**attributes.merge(trigger_name: trigger_name)) }
      let(:trigger_name) { 'trigger_with_custom_name' }

      it 'creates the trigger and function using the custom name' do
        expect_function_not_to_exist(trigger_name)
        expect_trigger_not_to_exist(table_name, trigger_name)

        create_trigger

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
      end
    end

    context 'when the trigger already exists' do
      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{trigger_name}()
          RETURNS trigger
          LANGUAGE plpgsql AS
          $$
          BEGIN
            RAISE NOTICE 'hello';
            RETURN NEW;
          END
          $$;

          CREATE TRIGGER #{trigger_name}
          BEFORE INSERT OR UPDATE
          ON #{table_name}
          FOR EACH ROW
          EXECUTE FUNCTION #{trigger_name}();
        SQL
      end

      it 'does not raise an error' do
        expect_function_to_exist(trigger_name)

        create_trigger

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
      end
    end

    context 'when parent_table_primary_key is provided' do
      let(:parent_table_pk) { :custom_primary_key }

      before do
        connection.execute('DROP TABLE IF EXISTS _test_project_parent CASCADE;')

        connection.execute(<<~SQL)
          CREATE TABLE _test_project_parent (
            custom_primary_key bigint NOT NULL PRIMARY KEY,
            parent_project_id bigint);

          INSERT INTO _test_project_parent (custom_primary_key, parent_project_id) VALUES
            (#{valid_project_parent_id}, #{valid_project_parent_sharding_key}),
            (#{invalid_project_parent_id}, NULL);
        SQL
      end

      it 'assigns the sharding key' do
        create_trigger

        record = model.create!(project_fk_id: valid_project_parent_id)
        expect(record.reload).to have_attributes(project_id: valid_project_parent_sharding_key)
      end
    end
  end

  describe '#drop' do
    subject(:drop_trigger) { trigger.drop }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id serial NOT NULL PRIMARY KEY,
          project_id integer NOT NULL);

        CREATE FUNCTION #{trigger_name}()
        RETURNS trigger
        LANGUAGE plpgsql AS
        $$
        BEGIN
          RAISE NOTICE 'hello';
          RETURN NEW;
        END
        $$;

        CREATE TRIGGER #{trigger_name}
        BEFORE INSERT OR UPDATE
        ON #{table_name}
        FOR EACH ROW
        EXECUTE FUNCTION #{trigger_name}();
      SQL
    end

    it 'drops the trigger and function for the given arguments' do
      expect_function_to_exist(trigger_name)
      expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])

      drop_trigger

      expect_trigger_not_to_exist(table_name, trigger_name)
      expect_function_not_to_exist(trigger_name)
    end

    context 'when the trigger has a custom name' do
      let(:trigger) { described_class.new(**attributes.merge(trigger_name: trigger_name)) }
      let(:trigger_name) { 'trigger_with_custom_name' }

      it 'drops the trigger and function for the given arguments' do
        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])

        drop_trigger

        expect_trigger_not_to_exist(table_name, trigger_name)
        expect_function_not_to_exist(trigger_name)
      end
    end

    context 'when the trigger does not exist' do
      it 'does not raise an error' do
        drop_trigger

        expect_trigger_not_to_exist(table_name, trigger_name)
        expect_function_not_to_exist(trigger_name)

        drop_trigger
      end
    end
  end
end
