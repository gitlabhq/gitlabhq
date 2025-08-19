# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateCiTriggersTokenToTokenEncrypted, feature_category: :continuous_integration, migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:ci_triggers) do
    table(:ci_triggers, database: :ci)
  end

  let!(:trigger1) { ci_triggers.create!(token: 'foo', owner_id: 1, project_id: 1) }
  let!(:trigger2) { ci_triggers.create!(token: 'bar', owner_id: 1, project_id: 1) }
  let!(:trigger3) { ci_triggers.create!(token: 'baz', owner_id: 1, project_id: 1) }

  subject(:perform_migration) do
    described_class.new(
      start_id: trigger1.id,
      end_id: trigger3.id,
      batch_table: 'ci_triggers',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 10,
      connection: connection
    ).perform
  end

  it 'migrates token to token_encrypted field' do
    expect(trigger1.reload[:token_encrypted]).to be_nil
    expect(trigger2.reload[:token_encrypted]).to be_nil
    expect(trigger3.reload[:token_encrypted]).to be_nil

    expect(Gitlab::BackgroundMigration::MigrateCiTriggersTokenToTokenEncrypted::CiTrigger.new.compute_token_prefix)
      .to eq('glptt-')
    perform_migration

    expect(trigger1.reload[:token_encrypted]).to eq(Ci::Trigger.encode(trigger1.reload.token))
    expect(trigger2.reload[:token_encrypted]).to eq(Ci::Trigger.encode(trigger2.reload.token))
    expect(trigger3.reload[:token_encrypted]).to eq(Ci::Trigger.encode(trigger3.reload.token))

    encrypted_token1 = trigger1.reload.token
    expect(encrypted_token1).to eq('foo')

    encrypted_token2 = trigger2.reload.token
    expect(encrypted_token2).to eq('bar')

    encrypted_token3 = trigger3.reload.token
    expect(encrypted_token3).to eq('baz')
  end
end
