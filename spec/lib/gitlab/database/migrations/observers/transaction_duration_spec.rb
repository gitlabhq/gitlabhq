# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::TransactionDuration do
  let!(:transaction_duration_observer) { described_class.new(observation, directory_path, connection) }

  let(:connection) { ActiveRecord::Migration.connection }
  let(:observation) { Gitlab::Database::Migrations::Observation.new(version: migration_version, name: migration_name) }
  let(:directory_path) { Dir.mktmpdir }
  let(:log_file) { "#{directory_path}/transaction-duration.json" }
  let(:transaction_duration) { Gitlab::Json.parse(File.read(log_file)) }
  let(:migration_version) { 20210422152437 }
  let(:migration_name) { 'test' }

  after do
    FileUtils.remove_entry(directory_path)
  end

  it 'records real and sub transactions duration', :delete do
    observe

    entry = transaction_duration[0]
    start_time, end_time, transaction_type = entry.values_at('start_time', 'end_time', 'transaction_type')
    start_time = DateTime.parse(start_time)
    end_time = DateTime.parse(end_time)

    aggregate_failures do
      expect(transaction_duration.size).to eq(3)
      expect(start_time).to be_before(end_time)
      expect(transaction_type).not_to be_nil
    end
  end

  context 'when there are sub-transactions' do
    it 'records transaction duration' do
      observe_sub_transaction

      expect(transaction_duration.size).to eq(1)

      entry = transaction_duration[0]['transaction_type']

      expect(entry).to eql 'sub_transaction'
    end
  end

  context 'when there are real-transactions' do
    it 'records transaction duration', :delete do
      observe_real_transaction

      expect(transaction_duration.size).to eq(1)

      entry = transaction_duration[0]['transaction_type']

      expect(entry).to eql 'real_transaction'
    end
  end

  private

  def observe
    transaction_duration_observer.before
    run_transaction
    transaction_duration_observer.after
    transaction_duration_observer.record
  end

  def observe_sub_transaction
    transaction_duration_observer.before
    run_sub_transactions
    transaction_duration_observer.after
    transaction_duration_observer.record
  end

  def observe_real_transaction
    transaction_duration_observer.before
    run_real_transactions
    transaction_duration_observer.after
    transaction_duration_observer.record
  end

  def run_real_transactions
    ApplicationRecord.transaction do
      User.first
    end
  end

  def run_sub_transactions
    ApplicationRecord.transaction(requires_new: true) do
      User.first
    end
  end

  def run_transaction
    ApplicationRecord.connection_pool.with_connection do |connection|
      Gitlab::Database::SharedModel.using_connection(connection) do
        User.first

        Gitlab::Database::SharedModel.transaction do
          User.first

          Gitlab::Database::SharedModel.transaction(requires_new: true) do
            User.first

            Gitlab::Database::SharedModel.transaction do
              User.first

              Gitlab::Database::SharedModel.transaction do
                User.first

                Gitlab::Database::SharedModel.transaction(requires_new: true) do
                  User.first
                end
              end
            end
          end
        end
      end
    end
  end
end
