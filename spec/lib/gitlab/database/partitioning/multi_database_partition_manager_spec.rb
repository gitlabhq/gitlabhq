# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::MultiDatabasePartitionManager, '#sync_partitions' do
  subject(:sync_partitions) { manager.sync_partitions }

  let(:manager) { described_class.new(models) }
  let(:models) { [model1, model2] }

  let(:model1) { double('model1', connection: connection1, table_name: 'table1') }
  let(:model2) { double('model2', connection: connection1, table_name: 'table2') }

  let(:connection1) { double('connection1') }
  let(:connection2) { double('connection2') }

  let(:target_manager_class) { Gitlab::Database::Partitioning::PartitionManager }
  let(:target_manager1) { double('partition manager') }
  let(:target_manager2) { double('partition manager') }

  before do
    allow(manager).to receive(:connection_name).and_return('name')
  end

  it 'syncs model partitions, setting up the appropriate connection for each', :aggregate_failures do
    expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(model1.connection).and_yield.ordered
    expect(target_manager_class).to receive(:new).with(model1).and_return(target_manager1).ordered
    expect(target_manager1).to receive(:sync_partitions)

    expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(model2.connection).and_yield.ordered
    expect(target_manager_class).to receive(:new).with(model2).and_return(target_manager2).ordered
    expect(target_manager2).to receive(:sync_partitions)

    sync_partitions
  end
end
