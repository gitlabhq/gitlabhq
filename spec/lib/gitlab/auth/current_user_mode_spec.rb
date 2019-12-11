# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::CurrentUserMode, :do_not_mock_admin_mode do
  include_context 'custom session'

  let(:user) { build(:user) }

  subject { described_class.new(user) }

  before do
    allow(ActiveSession).to receive(:list_sessions).with(user).and_return([session])
  end

  describe '#admin_mode?', :request_store do
    context 'when the user is a regular user' do
      it 'is false by default' do
        expect(subject.admin_mode?).to be(false)
      end

      it 'cannot be enabled with a valid password' do
        subject.enable_admin_mode!(password: user.password)

        expect(subject.admin_mode?).to be(false)
      end

      it 'cannot be enabled with an invalid password' do
        subject.enable_admin_mode!(password: nil)

        expect(subject.admin_mode?).to be(false)
      end

      it 'cannot be enabled with empty params' do
        subject.enable_admin_mode!

        expect(subject.admin_mode?).to be(false)
      end

      it 'disable has no effect' do
        subject.enable_admin_mode!
        subject.disable_admin_mode!

        expect(subject.admin_mode?).to be(false)
      end

      context 'skipping password validation' do
        it 'cannot be enabled with a valid password' do
          subject.enable_admin_mode!(password: user.password, skip_password_validation: true)

          expect(subject.admin_mode?).to be(false)
        end

        it 'cannot be enabled with an invalid password' do
          subject.enable_admin_mode!(skip_password_validation: true)

          expect(subject.admin_mode?).to be(false)
        end
      end
    end

    context 'when the user is an admin' do
      let(:user) { build(:user, :admin) }

      context 'when admin mode not requested' do
        it 'is false by default' do
          expect(subject.admin_mode?).to be(false)
        end

        it 'raises exception if we try to enable it' do
          expect do
            subject.enable_admin_mode!(password: user.password)
          end.to raise_error(::Gitlab::Auth::CurrentUserMode::NotRequestedError)

          expect(subject.admin_mode?).to be(false)
        end
      end

      context 'when admin mode requested first' do
        before do
          subject.request_admin_mode!
        end

        it 'is false by default' do
          expect(subject.admin_mode?).to be(false)
        end

        it 'cannot be enabled with an invalid password' do
          subject.enable_admin_mode!(password: nil)

          expect(subject.admin_mode?).to be(false)
        end

        it 'can be enabled with a valid password' do
          subject.enable_admin_mode!(password: user.password)

          expect(subject.admin_mode?).to be(true)
        end

        it 'can be disabled' do
          subject.enable_admin_mode!(password: user.password)
          subject.disable_admin_mode!

          expect(subject.admin_mode?).to be(false)
        end

        it 'will expire in the future' do
          subject.enable_admin_mode!(password: user.password)
          expect(subject.admin_mode?).to be(true), 'admin mode is not active in the present'

          Timecop.freeze(Gitlab::Auth::CurrentUserMode::MAX_ADMIN_MODE_TIME.from_now) do
            # in the future this will be a new request, simulate by clearing the RequestStore
            Gitlab::SafeRequestStore.clear!

            expect(subject.admin_mode?).to be(false), 'admin mode did not expire in the future'
          end
        end

        context 'skipping password validation' do
          it 'can be enabled with a valid password' do
            subject.enable_admin_mode!(password: user.password, skip_password_validation: true)

            expect(subject.admin_mode?).to be(true)
          end

          it 'can be enabled with an invalid password' do
            subject.enable_admin_mode!(skip_password_validation: true)

            expect(subject.admin_mode?).to be(true)
          end
        end

        context 'with two independent sessions' do
          let(:another_session) { {} }
          let(:another_subject) { described_class.new(user) }

          before do
            allow(ActiveSession).to receive(:list_sessions).with(user).and_return([session, another_session])
          end

          it 'can be enabled in one and seen in the other' do
            Gitlab::Session.with_session(another_session) do
              another_subject.request_admin_mode!
              another_subject.enable_admin_mode!(password: user.password)
            end

            expect(subject.admin_mode?).to be(true)
          end
        end
      end
    end
  end

  describe '#enable_admin_mode!' do
    let(:user) { build(:user, :admin) }

    it 'creates a timestamp in the session' do
      subject.request_admin_mode!
      subject.enable_admin_mode!(password: user.password)

      expect(session).to include(expected_session_entry(be_within(1.second).of Time.now))
    end
  end

  describe '#enable_sessionless_admin_mode!' do
    let(:user) { build(:user, :admin) }

    it 'enabled admin mode without password' do
      subject.enable_sessionless_admin_mode!

      expect(subject.admin_mode?).to be(true)
    end
  end

  describe '#disable_admin_mode!' do
    let(:user) { build(:user, :admin) }

    it 'sets the session timestamp to nil' do
      subject.request_admin_mode!
      subject.disable_admin_mode!

      expect(session).to include(expected_session_entry(be_nil))
    end
  end

  def expected_session_entry(value_matcher)
    {
      Gitlab::Auth::CurrentUserMode::SESSION_STORE_KEY => a_hash_including(
        Gitlab::Auth::CurrentUserMode::ADMIN_MODE_START_TIME_KEY => value_matcher)
    }
  end
end
