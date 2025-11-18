# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::TransactionRecord, feature_category: :cell do
  let(:connection) { ApplicationRecord.connection }
  let(:transaction) do
    instance_double(ActiveRecord::ConnectionAdapters::NullTransaction, add_record: nil)
  end

  let(:current_transaction) { transaction }

  before do
    allow(connection).to receive(:current_transaction).and_return(current_transaction)
    allow(GRPC::Core::TimeConsts).to receive(:from_relative_time).and_return("fake-deadline")
  end

  describe ".current_transaction" do
    subject(:transaction_record) { described_class.current_transaction(connection) }

    before do
      transaction.extend(Cells::TransactionRecord::TransactionExtension)

      allow(Current).to receive(:cells_claims_leases?).and_return(true)
      allow(transaction).to receive(:closed?).and_return(false)
    end

    context "when Current.cells_claims_leases? is false" do
      before do
        allow(Current).to receive(:cells_claims_leases?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context "when transaction is closed" do
      before do
        allow(transaction).to receive(:closed?).and_return(true)
      end

      it "raises an error" do
        expect { transaction_record }.to raise_error(described_class::Error, /requires transaction to be open/)
      end
    end

    context "when transaction already has a TransactionRecord" do
      let(:existing_record) { instance_double(described_class) }

      before do
        transaction.cells_current_transaction_record = existing_record
      end

      it { is_expected.to eq(existing_record) }
    end

    context "when transaction does not have a TransactionRecord" do
      it "creates and attaches a new TransactionRecord" do
        new_record = transaction_record
        expect(new_record).to be_a(described_class)
        expect(transaction.cells_current_transaction_record).to eq(new_record)
      end
    end
  end

  describe "#create_record and #destroy_record" do
    let(:record) { described_class.new(connection, transaction) }

    it "stores create metadata" do
      expect { record.create_record("meta1") }.to change { record.send(:create_records) }.to include("meta1")
    end

    it "stores destroy metadata" do
      expect { record.destroy_record("meta2") }.to change { record.send(:destroy_records) }.to include("meta2")
    end

    context "when after lease is created" do
      let(:lease) { instance_double(Cells::OutstandingLease) }

      before do
        allow(Cells::OutstandingLease).to receive_messages(create_from_request!: lease, connection: connection)
        record.before_committed!
      end

      it "raises if create_record is called" do
        expect { record.create_record("meta") }.to raise_error(described_class::Error, "Lease already created")
      end

      it "raises if destroy_record is called" do
        expect { record.destroy_record("meta") }.to raise_error(described_class::Error, "Lease already created")
      end
    end
  end

  describe "transaction lifecycle callbacks" do
    let(:record) { described_class.new(connection, transaction) }
    let(:lease) do
      instance_double(Cells::OutstandingLease, send_commit_update!: nil, send_rollback_update!: nil, destroy!: nil)
    end

    before do
      allow(Cells::OutstandingLease).to receive(:connection).and_return(connection)
    end

    describe "#before_committed!" do
      it "creates a lease" do
        expect(Cells::OutstandingLease).to receive(:create_from_request!).with(
          create_records: [],
          destroy_records: [],
          deadline: "fake-deadline"
        ).and_return(lease)

        record.before_committed!
        expect(record.send(:outstanding_lease)).to eq(lease)
      end

      it "raises if already done" do
        allow(Cells::OutstandingLease).to receive(:create_from_request!).and_return(lease)
        record.before_committed!
        record.committed!
        expect { record.before_committed! }.to raise_error(described_class::Error, "Already done")
      end

      it "raises if lease already created" do
        allow(Cells::OutstandingLease).to receive(:create_from_request!).and_return(lease)
        record.before_committed!
        expect { record.before_committed! }.to raise_error(described_class::Error, "Already created lease")
      end

      it "raises if connection mismatch" do
        allow(Cells::OutstandingLease)
          .to receive(:connection)
          .and_return(instance_double(Gitlab::Database::LoadBalancing::ConnectionProxy))

        expect do
          record.before_committed!
        end.to raise_error(described_class::Error, "Attributes can now only be claimed on main DB")
      end
    end

    describe "#committed!" do
      before do
        allow(Cells::OutstandingLease).to receive(:create_from_request!).and_return(lease)
        record.before_committed!
      end

      it "sends commit update and destroys lease" do
        expect(lease).to receive(:send_commit_update!).with(deadline: "fake-deadline")
        expect(lease).to receive(:destroy!)
        record.committed!
        expect(record.send(:done)).to be true
      end

      it "raises if already done" do
        record.committed!
        expect { record.committed! }.to raise_error(described_class::Error, "Already done")
      end

      it "raises if no lease created" do
        new_record = described_class.new(connection, transaction)
        expect { new_record.committed! }.to raise_error(described_class::Error, "No lease created")
      end
    end

    describe "#rolledback!" do
      before do
        allow(Cells::OutstandingLease).to receive(:create_from_request!).and_return(lease)
      end

      it "sends rollback update and destroys lease" do
        record.before_committed!
        expect(lease).to receive(:send_rollback_update!).with(deadline: "fake-deadline")
        expect(lease).to receive(:destroy!)
        record.rolledback!
        expect(record.send(:done)).to be true
      end

      it "does not raise if lease was never created" do
        new_record = described_class.new(connection, transaction)
        expect { new_record.rolledback! }.not_to raise_error
      end

      it "raises if already done" do
        record.before_committed!
        record.rolledback!
        expect { record.rolledback! }.to raise_error(described_class::Error, "Already done")
      end
    end
  end
end
