# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::ServiceDesk::CustomEmail, feature_category: :service_desk do
  let(:reply_key) { 'b7721fc7e8419911a8bea145236a0519' }
  let(:custom_email) { 'support@example.com' }
  let(:email_with_reply_key) { 'support+b7721fc7e8419911a8bea145236a0519@example.com' }

  describe '.reply_address' do
    let_it_be(:project) { create(:project) }

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
end
