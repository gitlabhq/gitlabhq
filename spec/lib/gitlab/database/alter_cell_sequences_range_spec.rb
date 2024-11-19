# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AlterCellSequencesRange, feature_category: :database do
  describe '#execute' do
    let(:connection) { ApplicationRecord.connection }
    let(:alter_cell_sequences_range) { described_class.new(*params, logger: logger) }
    let(:params) { [minval, maxval, connection] }
    let(:minval) { 100_000 }
    let(:maxval) { 200_000 }
    let(:default_min) { 1 }
    let(:default_max) { (2**63) - 1 }
    let(:logger) { instance_double(Gitlab::AppLogger, info: nil) }

    subject(:execute) { alter_cell_sequences_range.execute }

    context 'without minval and maxval' do
      let(:minval) { nil }
      let(:maxval) { nil }

      it 'raises an exception' do
        expect { execute }.to raise_error(described_class::MISSING_LIMIT_MSG)
      end
    end

    shared_examples 'alters sequences range' do
      it 'updates given limit(s) for all sequences' do
        execute

        if minval.present?
          incorrect_min = Gitlab::Database::PostgresSequence.where.not(seq_min: minval)
          expect(incorrect_min).to be_empty
        end

        if maxval.present?
          incorrect_max = Gitlab::Database::PostgresSequence.where.not(seq_max: maxval)
          expect(incorrect_max).to be_empty
        end

        expect(logger).to have_received(:info).with(match('Altered cell sequence')).at_least(:once)
      end
    end

    context 'with both minval and maxval' do
      it_behaves_like 'alters sequences range'
    end

    context 'with only minval' do
      let(:maxval) { nil }

      it_behaves_like 'alters sequences range'
    end

    context 'with only maxval' do
      let(:minval) { nil }

      it_behaves_like 'alters sequences range'
    end
  end
end
