# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::EncryptStaticObjectToken do
  let(:users) { table(:users) }
  let!(:user_without_tokens) { create_user!(name: 'notoken') }
  let!(:user_with_plaintext_token_1) { create_user!(name: 'plaintext_1', token: 'token') }
  let!(:user_with_plaintext_token_2) { create_user!(name: 'plaintext_2', token: 'TOKEN') }
  let!(:user_with_plaintext_empty_token) { create_user!(name: 'plaintext_3', token: '') }
  let!(:user_with_encrypted_token) { create_user!(name: 'encrypted', encrypted_token: 'encrypted') }
  let!(:user_with_both_tokens) { create_user!(name: 'both', token: 'token2', encrypted_token: 'encrypted2') }

  before do
    allow(Gitlab::CryptoHelper).to receive(:aes256_gcm_encrypt).and_call_original
    allow(Gitlab::CryptoHelper).to receive(:aes256_gcm_encrypt).with('token') { 'secure_token' }
    allow(Gitlab::CryptoHelper).to receive(:aes256_gcm_encrypt).with('TOKEN') { 'SECURE_TOKEN' }
  end

  subject { described_class.new.perform(start_id, end_id) }

  let(:start_id) { users.minimum(:id) }
  let(:end_id) { users.maximum(:id) }

  it 'backfills encrypted tokens to users with plaintext token only', :aggregate_failures do
    subject

    new_state = users.pluck(:id, :static_object_token, :static_object_token_encrypted).to_h do |row|
      [row[0], [row[1], row[2]]]
    end

    expect(new_state.count).to eq(6)

    expect(new_state[user_with_plaintext_token_1.id]).to match_array(%w[token secure_token])
    expect(new_state[user_with_plaintext_token_2.id]).to match_array(%w[TOKEN SECURE_TOKEN])

    expect(new_state[user_with_plaintext_empty_token.id]).to match_array(['', nil])
    expect(new_state[user_without_tokens.id]).to match_array([nil, nil])
    expect(new_state[user_with_both_tokens.id]).to match_array(%w[token2 encrypted2])
    expect(new_state[user_with_encrypted_token.id]).to match_array([nil, 'encrypted'])
  end

  context 'when id range does not include existing user ids' do
    let(:arguments) { [non_existing_record_id, non_existing_record_id.succ] }

    it_behaves_like 'marks background migration job records' do
      subject { described_class.new }
    end
  end

  private

  def create_user!(name:, token: nil, encrypted_token: nil)
    email = "#{name}@example.com"

    table(:users).create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      static_object_token: token,
      static_object_token_encrypted: encrypted_token
    )
  end
end
