# frozen_string_literal: true
#
require 'spec_helper'

RSpec.describe Constraints::AdminConstrainer do
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
    context 'application setting :admin_mode is enabled' do
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

    context 'application setting :admin_mode is disabled' do
      before do
        stub_application_setting(admin_mode: false)
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
