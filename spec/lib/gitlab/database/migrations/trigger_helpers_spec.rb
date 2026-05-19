# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::TriggerHelpers, feature_category: :database do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  describe '#install_rename_triggers' do
    let(:connection) { ActiveRecord::Migration.connection }

    it 'installs the triggers' do
      copy_trigger = instance_double(Gitlab::Database::UnidirectionalCopyTrigger)

      expect(Gitlab::Database::UnidirectionalCopyTrigger).to receive(:on_table)
        .with(:users, connection: connection).and_return(copy_trigger)

      expect(copy_trigger).to receive(:create).with(:old, :new, trigger_name: 'foo')

      model.install_rename_triggers(:users, :old, :new, trigger_name: 'foo')
    end
  end

  describe '#remove_rename_triggers' do
    let(:connection) { ActiveRecord::Migration.connection }

    it 'removes the function and trigger' do
      copy_trigger = instance_double(Gitlab::Database::UnidirectionalCopyTrigger)

      expect(Gitlab::Database::UnidirectionalCopyTrigger).to receive(:on_table)
        .with('bar', connection: connection).and_return(copy_trigger)

      expect(copy_trigger).to receive(:drop).with('foo')

      model.remove_rename_triggers('bar', 'foo')
    end
  end

  describe '#rename_trigger_name' do
    it 'returns a String' do
      expect(model.rename_trigger_name(:users, :foo, :bar))
        .to match(/trigger_.{12}/)
    end
  end

  describe '#install_sharding_key_assignment_trigger' do
    let(:trigger) { instance_double(Gitlab::Database::Triggers::AssignDesiredShardingKey) }
    let(:connection) { ActiveRecord::Base.connection }

    let(:args) do
      {
        table: :test_table, sharding_key: :project_id, parent_table: :parent_table,
        parent_table_primary_key: :project_id, parent_sharding_key: :parent_project_id,
        foreign_key: :foreign_key, trigger_name: 'trigger_name'
      }
    end

    it 'creates the sharding key assignment trigger' do
      expect(Gitlab::Database::Triggers::AssignDesiredShardingKey).to receive(:new)
        .with(**args, connection: connection).and_return(trigger)

      expect(trigger).to receive(:create)

      model.install_sharding_key_assignment_trigger(**args)
    end
  end

  describe '#remove_sharding_key_assignment_trigger' do
    let(:trigger) { instance_double(Gitlab::Database::Triggers::AssignDesiredShardingKey) }
    let(:connection) { ActiveRecord::Base.connection }

    let(:args) do
      {
        table: :test_table, sharding_key: :project_id, parent_table: :parent_table,
        parent_table_primary_key: :project_id, parent_sharding_key: :parent_project_id,
        foreign_key: :foreign_key, trigger_name: 'trigger_name'
      }
    end

    it 'removes the sharding key assignment trigger' do
      expect(Gitlab::Database::Triggers::AssignDesiredShardingKey).to receive(:new)
        .with(**args, connection: connection).and_return(trigger)

      expect(trigger).to receive(:drop)

      model.remove_sharding_key_assignment_trigger(**args)
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
end
