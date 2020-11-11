# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing do
  include ExclusiveLeaseHelpers

  describe '.perform' do
    subject { described_class.perform(indexes) }

    let(:coordinator) { instance_double(Gitlab::Database::Reindexing::Coordinator) }
    let(:indexes) { double }

    it 'delegates to Coordinator' do
      expect(Gitlab::Database::Reindexing::Coordinator).to receive(:new).with(indexes).and_return(coordinator)
      expect(coordinator).to receive(:perform)

      subject
    end
  end

  describe '.candidate_indexes' do
    subject { described_class.candidate_indexes }

    it 'retrieves regular indexes that are no left-overs from previous runs' do
      result = double
      expect(Gitlab::Database::PostgresIndex).to receive_message_chain('regular.where.not_match.not_match').with(no_args).with('NOT expression').with('^tmp_reindex_').with('^old_reindex_').and_return(result)

      expect(subject).to eq(result)
    end
  end
end
