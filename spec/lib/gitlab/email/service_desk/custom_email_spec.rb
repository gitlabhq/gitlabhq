# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::ServiceDesk::CustomEmail, feature_category: :service_desk do
  let(:reply_key) { 'b7721fc7e8419911a8bea145236a0519' }
  let(:custom_email) { 'support@example.com' }
  let(:email_with_reply_key) { 'support+b7721fc7e8419911a8bea145236a0519@example.com' }
  let_it_be(:project) { create(:project) }

  describe '.reply_address' do
    subject(:reply_address) { described_class.reply_address(nil, nil) }

    it { is_expected.to be nil }

    context 'with reply key' do
      subject(:reply_address) { described_class.reply_address(nil, reply_key) }

      it { is_expected.to be nil }

      context 'with issue' do
        let_it_be(:issue) { create(:issue, project: project) }

        subject(:reply_address) { described_class.reply_address(issue, reply_key) }

        it { is_expected.to be nil }

        context 'with service_desk_setting and custom email' do
          let!(:service_desk_setting) { create(:service_desk_setting, custom_email: custom_email, project: project) }

          it { is_expected.to eq(email_with_reply_key) }
        end
      end
    end
  end

  describe '.key_from_reply_address' do
    let(:email) { email_with_reply_key }

    subject(:reply_address) { described_class.key_from_reply_address(email) }

    it { is_expected.to be nil }

    context 'with service_desk_setting' do
      let_it_be_with_refind(:setting) do
        create(:service_desk_setting, project: project, add_external_participants_from_cc: true)
      end

      it { is_expected.to be nil }

      context 'with custom email' do
        let!(:credential) { create(:service_desk_custom_email_credential, project: project) }
        let!(:verification) { create(:service_desk_custom_email_verification, :finished, project: project) }

        before do
          project.reset
          setting.update!(custom_email: 'support@example.com', custom_email_enabled: true)
        end

        it { is_expected.to eq reply_key }
      end
    end

    context 'without reply key' do
      let(:email) { custom_email }

      it { is_expected.to be nil }
    end
  end
end
