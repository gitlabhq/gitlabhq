# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing do
  include ExclusiveLeaseHelpers

  describe '.perform' do
    subject { described_class.perform(candidate_indexes) }

    let(:coordinator) { instance_double(Gitlab::Database::Reindexing::Coordinator) }
    let(:index_selection) { instance_double(Gitlab::Database::Reindexing::IndexSelection) }
    let(:candidate_indexes) { double }
    let(:indexes) { [double, double] }

    it 'delegates to Coordinator' do
      expect(Gitlab::Database::Reindexing::IndexSelection).to receive(:new).with(candidate_indexes).and_return(index_selection)
      expect(index_selection).to receive(:take).with(2).and_return(indexes)

      indexes.each do |index|
        expect(Gitlab::Database::Reindexing::Coordinator).to receive(:new).with(index).and_return(coordinator)
        expect(coordinator).to receive(:perform)
      end

      subject
    end
  end

  describe '.candidate_indexes' do
    subject { described_class.candidate_indexes }

    context 'with deprecated method for < PG12' do
      before do
        stub_feature_flags(database_reindexing_pg12: false)
      end

      it 'retrieves regular indexes that are no left-overs from previous runs' do
        result = double
        expect(Gitlab::Database::PostgresIndex).to receive_message_chain('not_match.not_match.not_match.regular').with('^tmp_reindex_').with('^old_reindex_').with('\_ccnew[0-9]*$').with(no_args).and_return(result)

        expect(subject).to eq(result)
      end
    end

    context 'with deprecated method for >= PG12' do
      before do
        stub_feature_flags(database_reindexing_pg12: true)
      end

      it 'retrieves regular indexes that are no left-overs from previous runs' do
        result = double
        expect(Gitlab::Database::PostgresIndex).to receive_message_chain('not_match.not_match.not_match.reindexing_support').with('^tmp_reindex_').with('^old_reindex_').with('\_ccnew[0-9]*$').with(no_args).and_return(result)

        expect(subject).to eq(result)
      end
    end
  end
end
