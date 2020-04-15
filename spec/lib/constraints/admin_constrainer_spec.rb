# frozen_string_literal: true
#
require 'spec_helper'

describe Constraints::AdminConstrainer, :do_not_mock_admin_mode do
  let(:user) { create(:user) }

  let(:session) { {} }
  let(:env) { { 'warden' => double(:warden, authenticate?: true, user: user) } }
  let(:request) { double(:request, session: session, env: env) }

  around do |example|
    Gitlab::Session.with_session(session) do
      example.run
    end
  end

  describe '#matches' do
    context 'feature flag :user_mode_in_session is enabled' do
      context 'when user is a regular user' do
        it 'forbids access' do
          expect(subject.matches?(request)).to be(false)
        end
      end

      context 'when user is an admin' do
        let(:user) { create(:admin) }

        context 'admin mode is disabled' do
          it 'forbids access' do
            expect(subject.matches?(request)).to be(false)
          end
        end

        context 'admin mode is enabled' do
          before do
            current_user_mode = Gitlab::Auth::CurrentUserMode.new(user)
            current_user_mode.request_admin_mode!
            current_user_mode.enable_admin_mode!(password: user.password)
          end

          it 'allows access' do
            expect(subject.matches?(request)).to be(true)
          end
        end
      end
    end

    context 'feature flag :user_mode_in_session is disabled' do
      before do
        stub_feature_flags(user_mode_in_session: false)
      end

      context 'when user is a regular user' do
        it 'forbids access' do
          expect(subject.matches?(request)).to be(false)
        end
      end

      context 'when user is an admin' do
        let(:user) { create(:admin) }

        it 'allows access' do
          expect(subject.matches?(request)).to be(true)
        end
      end
    end
  end
end
