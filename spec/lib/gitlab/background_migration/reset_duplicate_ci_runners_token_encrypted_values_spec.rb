# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetDuplicateCiRunnersTokenEncryptedValues,
  :migration,
  schema: 20220922143634 do
  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchedMigrationJob }

  describe '#perform' do
    let(:ci_runners) { table(:ci_runners, database: :ci) }

    let(:test_worker) do
      described_class.new(
        start_id: 1,
        end_id: 4,
        batch_table: :ci_runners,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: Ci::ApplicationRecord.connection
      )
    end

    subject(:perform) { test_worker.perform }

    before do
      ci_runners.create!(id: 1, runner_type: 1, token_encrypted: 'duplicate')
      ci_runners.create!(id: 2, runner_type: 1, token_encrypted: 'a-token')
      ci_runners.create!(id: 3, runner_type: 1, token_encrypted: 'duplicate-2')
      ci_runners.create!(id: 4, runner_type: 1, token_encrypted: nil)
      ci_runners.create!(id: 5, runner_type: 1, token_encrypted: 'duplicate-2')
      ci_runners.create!(id: 6, runner_type: 1, token_encrypted: 'duplicate')
      ci_runners.create!(id: 7, runner_type: 1, token_encrypted: 'another-token')
      ci_runners.create!(id: 8, runner_type: 1, token_encrypted: 'another-token')
    end

    it 'nullifies duplicate encrypted tokens', :aggregate_failures do
      expect { perform }.to change { ci_runners.all.order(:id).pluck(:id, :token_encrypted).to_h }
                              .from(
                                {
                                  1 => 'duplicate',
                                  2 => 'a-token',
                                  3 => 'duplicate-2',
                                  4 => nil,
                                  5 => 'duplicate-2',
                                  6 => 'duplicate',
                                  7 => 'another-token',
                                  8 => 'another-token'
                                }
                              )
                              .to(
                                {
                                  1 => nil,
                                  2 => 'a-token',
                                  3 => nil,
                                  4 => nil,
                                  5 => nil,
                                  6 => nil,
                                  7 => 'another-token',
                                  8 => 'another-token'
                                }
                              )
      expect(ci_runners.count).to eq(8)
      expect(ci_runners.pluck(:token_encrypted).uniq).to match_array [
        nil, 'a-token', 'another-token'
      ]
    end
  end
end
