# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::PhoneNumberValidation, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:banned_user) { create(:user, :banned) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:banned_user) }

  it { is_expected.to validate_presence_of(:country) }
  it { is_expected.to validate_length_of(:country).is_at_most(3) }

  it { is_expected.to validate_presence_of(:international_dial_code) }

  it do
    is_expected.to validate_numericality_of(:international_dial_code)
      .only_integer
      .is_greater_than_or_equal_to(1)
      .is_less_than_or_equal_to(999)
  end

  it { is_expected.to validate_presence_of(:phone_number) }
  it { is_expected.to validate_length_of(:phone_number).is_at_most(12) }
  it { is_expected.to allow_value('555555').for(:phone_number) }
  it { is_expected.not_to allow_value('555-555').for(:phone_number) }
  it { is_expected.not_to allow_value('+555555').for(:phone_number) }
  it { is_expected.not_to allow_value('555 555').for(:phone_number) }

  it { is_expected.to validate_length_of(:telesign_reference_xid).is_at_most(255) }

  describe '#similar_records' do
    let_it_be(:phone_number_validation) { create(:phone_number_validation, :validated) }

    let_it_be(:phone_number) do
      phone_number_validation.attributes.with_indifferent_access.slice(
        :international_dial_code, :phone_number
      )
    end

    let_it_be(:match) { create(:phone_number_validation, :validated, phone_number) }
    let_it_be(:unvalidated_match) { create(:phone_number_validation, phone_number) }

    let_it_be(:non_match_1) { create(:phone_number_validation, phone_number.merge(international_dial_code: 81)) }
    let_it_be(:non_match_2) { create(:phone_number_validation, phone_number.merge(phone_number: '5555555555')) }

    it 'returns matches with the same international dialing code and phone number' do
      expect(phone_number_validation.similar_records).to match_array([unvalidated_match, match,
        phone_number_validation])
    end
  end

  describe '#duplicate_records' do
    let_it_be(:user) { create(:user) }
    let_it_be(:phone_number_validation) { create(:phone_number_validation, user: user) }

    let_it_be(:phone_number) do
      phone_number_validation.attributes.with_indifferent_access.slice(
        :international_dial_code, :phone_number
      )
    end

    let_it_be(:match) { create(:phone_number_validation, phone_number) }

    let_it_be(:non_match_1) { create(:phone_number_validation, phone_number.merge(international_dial_code: 81)) }
    let_it_be(:non_match_2) { create(:phone_number_validation, phone_number.merge(phone_number: '5555555555')) }

    it 'returns matches with the same international dialing code and phone number' do
      expect(phone_number_validation.duplicate_records).to match_array([match])
    end
  end

  describe '.related_to_banned_user?' do
    let_it_be(:international_dial_code) { 1 }
    let_it_be(:phone_number) { '555' }

    subject(:related_to_banned_user?) do
      described_class.related_to_banned_user?(international_dial_code, phone_number)
    end

    context 'when banned user has the same international dial code and phone number' do
      context 'and the matching record has not been verified' do
        before do
          create(
            :phone_number_validation,
            user: banned_user,
            international_dial_code: international_dial_code,
            phone_number: phone_number
          )
        end

        it { is_expected.to eq(false) }
      end

      context 'and the matching record has been verified' do
        before do
          create(
            :phone_number_validation,
            :validated,
            user: banned_user,
            international_dial_code: international_dial_code,
            phone_number: phone_number
          )
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'when banned user has the same international dial code and phone number, but different country code' do
      before do
        create(
          :phone_number_validation,
          :validated,
          user: banned_user,
          international_dial_code: international_dial_code,
          phone_number: phone_number,
          country: 'CA'
        )
      end

      it { is_expected.to eq(true) }
    end

    context 'when banned user does not have the same international dial code' do
      before do
        create(
          :phone_number_validation,
          :validated,
          user: banned_user,
          international_dial_code: 81,
          phone_number: phone_number
        )
      end

      it { is_expected.to eq(false) }
    end

    context 'when banned user does not have the same phone number' do
      before do
        create(
          :phone_number_validation,
          :validated,
          user: banned_user,
          international_dial_code: international_dial_code,
          phone_number: '666'
        )
      end

      it { is_expected.to eq(false) }
    end

    context 'when not-banned user has the same international dial code and phone number' do
      before do
        create(
          :phone_number_validation,
          :validated,
          user: user,
          international_dial_code: international_dial_code,
          phone_number: phone_number
        )
      end

      it { is_expected.to eq(false) }
    end
  end

  describe 'scopes' do
    let_it_be(:another_user) { create(:user) }

    let_it_be(:phone_number_record_1) { create(:phone_number_validation, user: user, telesign_reference_xid: 'target') }
    let_it_be(:phone_number_record_2) { create(:phone_number_validation, user: another_user) }

    describe '#for_user' do
      context 'when multiple records exist for multiple users' do
        it 'returns the correct phone number record for user' do
          records = described_class.for_user(user.id)

          expect(records.count).to be(1)
          expect(records.first).to eq(phone_number_record_1)
        end
      end
    end

    describe '.similar_to' do
      subject(:similar_to) { described_class.similar_to(phone_number_validation) }

      let_it_be(:international_dial_code) { 44 }
      let_it_be(:phone_number) { '111' }

      let_it_be(:phone_number_validation) do
        create(:phone_number_validation,
          :validated,
          international_dial_code: international_dial_code,
          phone_number: phone_number
        )
      end

      let_it_be(:match) do
        create(:phone_number_validation,
          :validated,
          international_dial_code: phone_number_validation.international_dial_code,
          phone_number: phone_number_validation.phone_number
        )
      end

      let_it_be(:non_match_1) do
        create(:phone_number_validation,
          :validated,
          international_dial_code: phone_number_validation.international_dial_code,
          phone_number: '222'
        )
      end

      let_it_be(:non_match_2) do
        create(:phone_number_validation,
          :validated,
          international_dial_code: 81,
          phone_number: phone_number_validation.phone_number
        )
      end

      let_it_be(:non_match_3) do
        create(:phone_number_validation,
          :validated,
          international_dial_code: 82,
          phone_number: '333'
        )
      end

      it 'returns only records with the same international dialing code and phone number' do
        expect(similar_to).to match_array([phone_number_validation, match])
      end
    end
  end

  describe '#validated?' do
    let_it_be(:phone_number_record) { create(:phone_number_validation, user: user) }

    context 'when phone number record is not validated' do
      it 'returns false' do
        expect(phone_number_record.validated?).to be(false)
      end
    end

    context 'when phone number record is validated' do
      before do
        phone_number_record.update!(validated_at: Time.now.utc)
      end

      it 'returns true' do
        expect(phone_number_record.validated?).to be(true)
      end
    end
  end

  describe '.by_reference_id' do
    let_it_be(:phone_number_record) { create(:phone_number_validation) }

    let(:ref_id) { phone_number_record.telesign_reference_xid }

    subject { described_class.by_reference_id(ref_id) }

    it { is_expected.to eq phone_number_record }

    context 'when there is no matching record' do
      let(:ref_id) { 'does-not-exist' }

      it { is_expected.to be_nil }
    end
  end

  describe '.sms_send_allowed_after' do
    let_it_be(:record) { create(:phone_number_validation, sms_send_count: 0) }

    subject(:result) { record.sms_send_allowed_after }

    context 'when there are no attempts yet' do
      it { is_expected.to be_nil }
    end

    where(:attempt_number, :expected_delay) do
      2 | 1.minute
      3 | 3.minutes
      4 | 5.minutes
      5 | 10.minutes
      6 | 10.minutes
    end

    with_them do
      it 'returns the correct delayed timestamp value' do
        freeze_time do
          record.update!(sms_send_count: attempt_number - 1, sms_sent_at: Time.current)

          expected_result = Time.current + expected_delay
          expect(result).to eq expected_result
        end
      end
    end
  end
end
