# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresHll::BatchDistinctCounter do
  let_it_be(:error_rate) { described_class::ERROR_RATE } # HyperLogLog is a probabilistic algorithm, which provides estimated data, with given error margin
  let_it_be(:fallback) { ::Gitlab::Database::BatchCounter::FALLBACK }
  let_it_be(:small_batch_size) { calculate_batch_size(described_class::MIN_REQUIRED_BATCH_SIZE) }
  let(:model) { Issue }
  let(:column) { :author_id }

  let(:in_transaction) { false }

  let_it_be(:user) { create(:user, email: 'email1@domain.com') }
  let_it_be(:another_user) { create(:user, email: 'email2@domain.com') }

  def calculate_batch_size(batch_size)
    zero_offset_modifier = -1

    batch_size + zero_offset_modifier
  end

  before do
    allow(model.connection).to receive(:transaction_open?).and_return(in_transaction)
  end

  context 'unit test for different counting parameters' do
    before_all do
      create_list(:issue, 3, author: user)
      create_list(:issue, 2, author: another_user)
    end

    describe '#execute' do
      it 'builds hll buckets' do
        expect(described_class.new(model).execute).to be_an_instance_of(Gitlab::Database::PostgresHll::Buckets)
      end

      it "defaults batch size to #{Gitlab::Database::PostgresHll::BatchDistinctCounter::DEFAULT_BATCH_SIZE}" do
        min_id = model.minimum(:id)
        batch_end_id = min_id + calculate_batch_size(Gitlab::Database::PostgresHll::BatchDistinctCounter::DEFAULT_BATCH_SIZE)

        expect(model).to receive(:where).with("id" => min_id..batch_end_id).and_call_original

        described_class.new(model).execute
      end

      context 'when a transaction is open' do
        let(:in_transaction) { true }

        it 'raises an error' do
          expect { described_class.new(model, column).execute }.to raise_error('BatchCount can not be run inside a transaction')
        end
      end

      context 'disallowed configurations' do
        let(:default_batch_size) { Gitlab::Database::PostgresHll::BatchDistinctCounter::DEFAULT_BATCH_SIZE }

        it 'raises WRONG_CONFIGURATION_ERROR if start is bigger than finish' do
          expect { described_class.new(model, column).execute(start: 1, finish: 0) }.to raise_error(described_class::WRONG_CONFIGURATION_ERROR)
        end

        it 'raises WRONG_CONFIGURATION_ERROR if data volume exceeds upper limit' do
          large_finish = Gitlab::Database::PostgresHll::BatchDistinctCounter::MAX_DATA_VOLUME + 1
          expect { described_class.new(model, column).execute(start: 1, finish: large_finish) }.to raise_error(described_class::WRONG_CONFIGURATION_ERROR)
        end

        it 'raises WRONG_CONFIGURATION_ERROR if batch size is less than min required' do
          expect { described_class.new(model, column).execute(batch_size: small_batch_size) }.to raise_error(described_class::WRONG_CONFIGURATION_ERROR)
        end
      end
    end
  end
end
