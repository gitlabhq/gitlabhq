# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ConvertCreditCardValidationDataToHashes, schema: 20230721095222, feature_category: :user_profile do
  let(:users_table) { table(:users) }
  let(:credit_card_validations_table) { table(:user_credit_card_validations) }
  let(:rows) { 5 }

  describe '#perform' do
    let(:network) { 'Visa' }
    let(:holder_name) { 'John Smith' }
    let(:last_digits) { 1111 }
    let(:expiration_date) { 1.year.from_now.to_date }

    subject(:perform_migration) do
      described_class.new(
        start_id: 1,
        end_id: rows,
        batch_table: :user_credit_card_validations,
        batch_column: :user_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    before do
      (1..rows).each do |i|
        users_table.create!(id: i, username: "John #{i}", email: "johndoe_#{i}@gitlab.com", projects_limit: 10)

        credit_card_validations_table.create!(
          id: i,
          user_id: i,
          network: network,
          holder_name: holder_name,
          last_digits: last_digits,
          expiration_date: expiration_date,
          credit_card_validated_at: Date.today
        )
      end
    end

    it 'updates values to hash for records in the specified batch', :aggregate_failures do
      perform_migration

      (1..rows).each do |i|
        credit_card = credit_card_validations_table.find_by(user_id: i)

        expect(credit_card.last_digits_hash).to eq(hashed_value(last_digits))
        expect(credit_card.holder_name_hash).to eq(hashed_value(holder_name.downcase))
        expect(credit_card.network_hash).to eq(hashed_value(network.downcase))
        expect(credit_card.expiration_date_hash).to eq(hashed_value(expiration_date.to_s))
      end
    end

    context 'with NULL columns' do
      let(:network) { nil }
      let(:holder_name) { nil }
      let(:last_digits) { nil }
      let(:expiration_date) { nil }

      it 'does not update values for records in the specified batch', :aggregate_failures do
        perform_migration

        (1..rows).each do |i|
          credit_card = credit_card_validations_table.find_by(user_id: i)

          expect(credit_card.last_digits_hash).to eq(nil)
          expect(credit_card.holder_name_hash).to eq(nil)
          expect(credit_card.network_hash).to eq(nil)
          expect(credit_card.expiration_date_hash).to eq(nil)
        end
      end
    end
  end

  def hashed_value(value)
    Gitlab::CryptoHelper.sha256(value)
  end
end
