# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::MultiDatabasePartitionDropper, '#drop_detached_partitions' do
  subject(:drop_detached_partitions) { multi_db_dropper.drop_detached_partitions }

  let(:multi_db_dropper) { described_class.new }

  let(:connection_wrapper1) { double(scope: scope1) }
  let(:connection_wrapper2) { double(scope: scope2) }

  let(:scope1) { double(connection: connection1) }
  let(:scope2) { double(connection: connection2) }

  let(:connection1) { double('connection') }
  let(:connection2) { double('connection') }

  let(:dropper_class) { Gitlab::Database::Partitioning::DetachedPartitionDropper }
  let(:dropper1) { double('partition dropper') }
  let(:dropper2) { double('partition dropper') }

  before do
    allow(multi_db_dropper).to receive(:databases).and_return({ db1: connection_wrapper1, db2: connection_wrapper2 })
  end

  it 'drops detached partitions for each database' do
    expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(connection1).and_yield.ordered
    expect(dropper_class).to receive(:new).and_return(dropper1).ordered
    expect(dropper1).to receive(:perform)

    expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(connection2).and_yield.ordered
    expect(dropper_class).to receive(:new).and_return(dropper2).ordered
    expect(dropper2).to receive(:perform)

    drop_detached_partitions
  end
end
