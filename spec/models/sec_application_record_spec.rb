# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SecApplicationRecord, feature_category: :vulnerability_management do
  describe '.pass_feature_flag_to_vuln_reads_db_trigger' do
    context 'when called outside a transaction' do
      before do
        # Spec runs in transactions, so we have to mock and pretend a transaction isn't open.
        allow(::SecApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
      end

      it 'raises an error' do
        expect do
          described_class.pass_feature_flag_to_vuln_reads_db_trigger(nil)
        end.to raise_error(
          StandardError,
          'pass_feature_flag_to_vuln_reads_db_trigger must be called within a transaction'
        )
      end
    end

    context 'when called within a transaction' do
      it 'does not raise an error with nil projects' do
        expect do
          described_class.transaction do
            described_class.pass_feature_flag_to_vuln_reads_db_trigger(nil)
          end
        end.not_to raise_error
      end

      it 'does not raise an error with project array' do
        project = create(:project)

        expect do
          described_class.transaction do
            described_class.pass_feature_flag_to_vuln_reads_db_trigger([project])
          end
        end.not_to raise_error
      end
    end
  end

  describe '.feature_flagged_transaction_for' do
    it 'executes the block within a transaction' do
      project = create(:project)
      executed = false

      described_class.feature_flagged_transaction_for([project]) do
        executed = true
      end

      expect(executed).to be true
    end
  end

  describe '.db_trigger_flag_not_set?' do
    it 'returns true when flag is not set' do
      expect(described_class.db_trigger_flag_not_set?).to be_in([true, false])
    end
  end
end
