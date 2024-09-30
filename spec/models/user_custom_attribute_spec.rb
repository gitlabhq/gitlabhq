# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserCustomAttribute, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  describe 'assocations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build :user_custom_attribute }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:user_id) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:blocked_at) { DateTime.now }
    let(:custom_attribute) { create(:user_custom_attribute, key: 'blocked_at', value: blocked_at, user_id: user.id) }

    describe '.by_user_id' do
      subject { described_class.by_user_id(user.id) }

      it { is_expected.to match_array([custom_attribute]) }
    end

    describe '.by_updated_at' do
      subject { described_class.by_updated_at(Date.today.all_day) }

      it { is_expected.to match_array([custom_attribute]) }
    end

    describe '.by_key' do
      subject { described_class.by_key('blocked_at') }

      it { is_expected.to match_array([custom_attribute]) }
    end
  end

  describe '.set_banned_by_abuse_report' do
    let_it_be(:user) { create(:user) }
    let(:abuse_report) { create(:abuse_report, user: user) }

    subject { described_class.set_banned_by_abuse_report(abuse_report) }

    it 'adds the abuse report ID to user custom attributes' do
      subject

      custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_ABUSE_REPORT_ID)
      expect(custom_attribute.map(&:value)).to match([abuse_report.id.to_s])
    end

    context 'when abuse report is nil' do
      let(:abuse_report) { nil }

      it 'does not update custom attributes' do
        subject

        custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_ABUSE_REPORT_ID).first
        expect(custom_attribute).to be_nil
      end
    end
  end

  describe '.set_banned_by_spam_log' do
    let_it_be(:user) { create(:user) }
    let(:spam_log) { create(:spam_log, user: user) }

    subject { described_class.set_banned_by_spam_log(spam_log) }

    it 'adds the spam log ID to user custom attributes' do
      subject

      custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_SPAM_LOG_ID)
      expect(custom_attribute.map(&:value)).to match([spam_log.id.to_s])
    end

    context 'when the spam log is nil' do
      let(:spam_log) { nil }

      it 'does not update custom attributes' do
        subject

        custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_SPAM_LOG_ID).first
        expect(custom_attribute).to be_nil
      end
    end
  end

  describe '.set_auto_banned_by' do
    let_it_be(:user) { create(:user) }

    subject { described_class.set_auto_banned_by(user: user, reason: 'testing') }

    it 'adds the auto_banned_by key to user custom attributes' do
      subject

      custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY).first
      expect(custom_attribute.value).to eq('testing')
    end
  end

  describe '#upsert_custom_attributes' do
    subject { described_class.upsert_custom_attributes(custom_attributes) }

    let_it_be_with_reload(:user) { create(:user) }

    let(:arkose_session) { '22612c147bb418c8.2570749403' }
    let(:risk_band) { 'Low' }
    let(:global_score) { '0' }
    let(:custom_score) { '0' }

    let(:custom_attributes) do
      custom_attributes = []
      custom_attributes.push({ key: 'arkose_session', value: arkose_session })
      custom_attributes.push({ key: 'arkose_risk_band', value: risk_band })
      custom_attributes.push({ key: 'arkose_global_score', value: global_score })
      custom_attributes.push({ key: 'arkose_custom_score', value: custom_score })

      custom_attributes.map! { |custom_attribute| custom_attribute.merge({ user_id: user.id }) }
      custom_attributes
    end

    it 'adds arkose data to custom attributes' do
      subject

      expect(user.custom_attributes.count).to eq(4)

      expect(user.custom_attributes.find_by(key: 'arkose_session').value).to eq(arkose_session)
      expect(user.custom_attributes.find_by(key: 'arkose_risk_band').value).to eq(risk_band)
      expect(user.custom_attributes.find_by(key: 'arkose_global_score').value).to eq(global_score)
      expect(user.custom_attributes.find_by(key: 'arkose_custom_score').value).to eq(custom_score)
    end
  end

  describe '.set_deleted_own_account_at' do
    let_it_be(:user) { create(:user) }

    subject(:method_call) { described_class.set_deleted_own_account_at(user) }

    it 'creates a custom attribute with "deleted_own_account_at" key associated to the user' do
      freeze_time do
        expect { method_call }.to change { user.custom_attributes.count }.by(1)

        record = user.custom_attributes.find_by_key(UserCustomAttribute::DELETED_OWN_ACCOUNT_AT)
        expect(record.value).to eq Time.zone.now.to_s
      end
    end

    context 'when passed in user is nil' do
      let(:user) { nil }

      it 'does nothing' do
        expect { method_call }.not_to change { UserCustomAttribute.count }
      end
    end
  end

  describe '.set_skipped_account_deletion_at' do
    let_it_be(:user) { create(:user) }

    subject(:method_call) { described_class.set_skipped_account_deletion_at(user) }

    it 'creates a custom attribute with "skipped_account_deletion_at" key associated to the user' do
      freeze_time do
        expect { method_call }.to change { user.custom_attributes.count }.by(1)

        record = user.custom_attributes.find_by_key(UserCustomAttribute::SKIPPED_ACCOUNT_DELETION_AT)
        expect(record.value).to eq Time.zone.now.to_s
      end
    end

    context 'when passed in user is nil' do
      let(:user) { nil }

      it 'does nothing' do
        expect { method_call }.not_to change { UserCustomAttribute.count }
      end
    end
  end

  describe '#upsert_custom_attribute' do
    let_it_be(:user) { create(:user) }

    let(:user_id) { user.id }

    where(:id, :key, :value, :created) do
      nil           | 'key1' | 'value1' | false
      ref(:user_id) | nil    | 'value2' | false
      ref(:user_id) | 'key2' | nil      | false
      ref(:user_id) | 'key3' | 'value3' | true
    end

    with_them do
      it do
        described_class.upsert_custom_attribute(user_id: id, key: key, value: value)

        record_exists = user.custom_attributes.where(key: key, value: value).exists?
        expect(record_exists).to eq created
      end
    end
  end
end
