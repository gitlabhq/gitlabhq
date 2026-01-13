# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Iam::AuthenticationService, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:token) { 'sample_jwt_token' }
  let(:service) { described_class.new(token) }

  describe '#execute' do
    context 'when user_id is nil' do
      it 'returns feature disabled error' do
        result = service.execute

        expect(result).to eq({ status: :error, message: 'IAM Service authentication is not enabled' })
      end
    end

    context 'when feature is enabled for user' do
      let(:user) { create(:user) }

      before do
        allow(service).to receive(:user_id).and_return(user.id)
        stub_feature_flags(iam_svc_oauth: user)
      end

      it 'returns not implemented error' do
        result = service.execute

        expect(result).to eq({ status: :error, message: 'IAM Service authentication not yet implemented' })
      end
    end
  end

  describe '#user_id' do
    it 'returns nil as placeholder' do
      expect(service.send(:user_id)).to be_nil
    end
  end

  describe '#feature_enabled_for_user?' do
    subject(:feature_check) { service.send(:feature_enabled_for_user?, user_id) }

    context 'when user_id is nil' do
      let(:user_id) { nil }

      it { is_expected.to be(false) }
    end

    context 'when user_id is provided' do
      where(:user_exists, :feature_enabled, :expected_result) do
        false | false | false
        false | true  | false
        true  | false | false
        true  | true  | true
      end

      with_them do
        let(:user) { user_exists ? create(:user) : nil }
        let(:user_id) { user_exists ? user.id : non_existing_record_id }

        before do
          stub_feature_flags(iam_svc_oauth: feature_enabled ? user : false) if user_exists
        end

        it 'returns the correct result' do
          expect(feature_check).to be(expected_result)
        end
      end
    end
  end
end
