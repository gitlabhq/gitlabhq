# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::AuthTokenService, feature_category: :virtual_registry do
  include DependencyProxyHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:group_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token) }

  shared_examples 'handling token errors' do
    context 'with a decoding error' do
      before do
        allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)
      end

      it { is_expected.to eq(nil) }
    end

    context 'with an immature signature error' do
      before do
        allow(JWT).to receive(:decode).and_raise(JWT::ImmatureSignature)
      end

      it { is_expected.to eq(nil) }
    end

    context 'with an expired signature error' do
      it 'returns nil' do
        travel_to(Time.zone.now + Auth::DependencyProxyAuthenticationService.token_expire_at + 1.minute) do
          expect(subject).to eq(nil)
        end
      end
    end
  end

  describe '.user_or_deploy_token_from_jwt' do
    subject { described_class.user_or_deploy_token_from_jwt(token.encoded) }

    shared_examples 'handling token errors' do
      context 'with a decoding error' do
        before do
          allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)
        end

        it { is_expected.to eq(nil) }
      end

      context 'with an immature signature error' do
        before do
          allow(JWT).to receive(:decode).and_raise(JWT::ImmatureSignature)
        end

        it { is_expected.to eq(nil) }
      end

      context 'with an expired signature error' do
        it 'returns nil' do
          travel_to(Time.zone.now + Auth::DependencyProxyAuthenticationService.token_expire_at + 1.minute) do
            expect(subject).to eq(nil)
          end
        end
      end
    end

    context 'with a user' do
      let_it_be(:token) { build_jwt(user) }

      it { is_expected.to eq(user) }

      context 'with an invalid user id' do
        let_it_be(:token) { build_jwt { |jwt| jwt['user_id'] = 'this_is_not_a_user_id' } }

        it 'raises an not found error' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it_behaves_like 'handling token errors'
    end

    context 'with a deploy token' do
      let_it_be(:token) { build_jwt(deploy_token) }

      it { is_expected.to eq(deploy_token) }

      context 'with an invalid token' do
        let_it_be(:token) { build_jwt { |jwt| jwt['deploy_token'] = 'this_is_not_a_token' } }

        it { is_expected.to eq(nil) }
      end

      it_behaves_like 'handling token errors'
    end

    context 'with an empty token payload' do
      let_it_be(:token) { build_jwt(nil) }

      it { is_expected.to eq(nil) }
    end
  end

  describe '.user_or_token_from_jwt' do
    subject { described_class.user_or_token_from_jwt(token.encoded) }

    context 'with a user' do
      let_it_be(:token) { build_jwt(user) }

      it { is_expected.to eq(user) }

      context 'with an invalid user id' do
        let_it_be(:token) { build_jwt { |jwt| jwt['user_id'] = 'this_is_not_a_user_id' } }

        it 'raises an not found error' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it_behaves_like 'handling token errors'
    end

    context 'with a personal access token' do
      let_it_be(:token) { build_jwt(personal_access_token) }

      it { is_expected.to eq(personal_access_token) }

      context 'with an inactive token' do
        before do
          personal_access_token.revoke!
        end

        it { is_expected.to eq(nil) }
      end

      context 'with an invalid token' do
        let_it_be(:token) { build_jwt { |jwt| jwt['personal_access_token'] = 'this_is_not_a_token' } }

        it { is_expected.to eq(nil) }
      end
    end

    context 'with a group access token' do
      let_it_be(:token) { build_jwt(group_access_token) }

      it { is_expected.to eq(group_access_token) }

      context 'with an inactive token' do
        before do
          group_access_token.revoke!
        end

        it { is_expected.to eq(nil) }
      end

      context 'with an invalid token' do
        let_it_be(:token) { build_jwt { |jwt| jwt['group_access_token'] = 'this_is_not_a_token' } }

        it { is_expected.to eq(nil) }
      end
    end

    context 'with a deploy token' do
      let_it_be(:token) { build_jwt(deploy_token) }

      it { is_expected.to eq(deploy_token) }

      context 'with an invalid token' do
        let_it_be(:token) { build_jwt { |jwt| jwt['deploy_token'] = 'this_is_not_a_token' } }

        it { is_expected.to eq(nil) }
      end

      it_behaves_like 'handling token errors'
    end

    context 'with an empty token payload' do
      let_it_be(:token) { build_jwt(nil) }

      it { is_expected.to eq(nil) }
    end
  end
end
