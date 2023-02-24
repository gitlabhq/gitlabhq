# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints::ForeignKeyValidator, feature_category: :database do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let!(:lease) { stub_exclusive_lease(lease_key, :uuid, timeout: lease_timeout) }
    let(:lease_key) { "gitlab/database/asyncddl/actions/#{Gitlab::Database::PRIMARY_DATABASE_NAME}" }
    let(:lease_timeout) { described_class::TIMEOUT_PER_ACTION }

    let(:fk_model) { Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation }
    let(:table_name) { '_test_async_fks' }
    let(:fk_name) { 'fk_parent_id' }
    let(:validation) { create(:postgres_async_constraint_validation, table_name: table_name, name: fk_name) }
    let(:connection) { validation.connection }

    subject { described_class.new(validation) }

    before do
      connection.create_table(table_name) do |t|
        t.references :parent, foreign_key: { to_table: table_name, validate: false, name: fk_name }
      end
    end

    it 'validates the FK while controlling statement timeout' do
      allow(connection).to receive(:execute).and_call_original
      expect(connection).to receive(:execute)
        .with("SET statement_timeout TO '43200s'").ordered.and_call_original
      expect(connection).to receive(:execute)
        .with('ALTER TABLE "_test_async_fks" VALIDATE CONSTRAINT "fk_parent_id";').ordered.and_call_original
      expect(connection).to receive(:execute)
        .with("RESET statement_timeout").ordered.and_call_original

      subject.perform
    end

    context 'with fully qualified table names' do
      let(:validation) do
        create(:postgres_async_constraint_validation,
          table_name: "public.#{table_name}",
          name: fk_name
        )
      end

      it 'validates the FK' do
        allow(connection).to receive(:execute).and_call_original

        expect(connection).to receive(:execute)
          .with('ALTER TABLE "public"."_test_async_fks" VALIDATE CONSTRAINT "fk_parent_id";').ordered.and_call_original

        subject.perform
      end
    end

    it 'removes the FK validation record from table' do
      expect(validation).to receive(:destroy!).and_call_original

      expect { subject.perform }.to change { fk_model.count }.by(-1)
    end

    it 'skips logic if not able to acquire exclusive lease' do
      expect(lease).to receive(:try_obtain).ordered.and_return(false)
      expect(connection).not_to receive(:execute).with(/ALTER TABLE/)
      expect(validation).not_to receive(:destroy!)

      expect { subject.perform }.not_to change { fk_model.count }
    end

    it 'logs messages around execution' do
      allow(Gitlab::AppLogger).to receive(:info).and_call_original

      subject.perform

      expect(Gitlab::AppLogger)
        .to have_received(:info)
        .with(a_hash_including(message: 'Starting to validate foreign key'))

      expect(Gitlab::AppLogger)
        .to have_received(:info)
        .with(a_hash_including(message: 'Finished validating foreign key'))
    end

    context 'when the FK does not exist' do
      before do
        connection.create_table(table_name, force: true)
      end

      it 'skips validation and removes the record' do
        expect(connection).not_to receive(:execute).with(/ALTER TABLE/)

        expect { subject.perform }.to change { fk_model.count }.by(-1)
      end

      it 'logs an appropriate message' do
        expected_message = "Skipping #{fk_name} validation since it does not exist. The queuing entry will be deleted"

        allow(Gitlab::AppLogger).to receive(:info).and_call_original

        subject.perform

        expect(Gitlab::AppLogger)
          .to have_received(:info)
          .with(a_hash_including(message: expected_message))
      end
    end

    context 'with error handling' do
      before do
        allow(connection).to receive(:execute).and_call_original

        allow(connection).to receive(:execute)
          .with('ALTER TABLE "_test_async_fks" VALIDATE CONSTRAINT "fk_parent_id";')
          .and_raise(ActiveRecord::StatementInvalid)
      end

      context 'on production' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
        end

        it 'increases execution attempts' do
          expect { subject.perform }.to change { validation.attempts }.by(1)

          expect(validation.last_error).to be_present
          expect(validation).not_to be_destroyed
        end

        it 'logs an error message including the fk_name' do
          expect(Gitlab::AppLogger)
            .to receive(:error)
            .with(a_hash_including(:message, :fk_name))
            .and_call_original

          subject.perform
        end
      end

      context 'on development' do
        it 'also raises errors' do
          expect { subject.perform }
            .to raise_error(ActiveRecord::StatementInvalid)
            .and change { validation.attempts }.by(1)

          expect(validation.last_error).to be_present
          expect(validation).not_to be_destroyed
        end
      end
    end
  end
end
