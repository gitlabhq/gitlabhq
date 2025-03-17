# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::CurrentUserMode, :request_store, feature_category: :system_access do
  let(:user) { build_stubbed(:user) }

  subject { described_class.new(user) }

  describe '#initialize' do
    context 'with user' do
      around do |example|
        Gitlab::Session.with_session(nil) do
          example.run
        end
      end

      it 'has no session' do
        subject
        expect(Gitlab::Session.current).to be_nil
      end
    end

    context 'with user and session' do
      include_context 'custom session'
      let(:session) { { 'key' => "value" } }

      it 'has a session' do
        described_class.new(user, session)
        expect(Gitlab::Session.current).to eq(session)
      end
    end
  end

  describe '#current_session_data' do
    include_context 'custom session'
    let(:session) { { 'key' => "value" } }

    it 'without session' do
      expect(Gitlab::Session.current).to eq(session)

      expect(Gitlab::NamespacedSessionStore).to receive(:new).with(described_class::SESSION_STORE_KEY, session)

      subject.current_session_data
      expect(Gitlab::Session.current).to eq(session)
    end

    it 'with session' do
      expect(Gitlab::Session.current).to eq(session)
      subject = described_class.new(user, session)

      expect(Gitlab::NamespacedSessionStore).to receive(:new).with(described_class::SESSION_STORE_KEY, session)

      subject.current_session_data
      expect(Gitlab::Session.current).to eq(session)
    end
  end

  context 'when session is available' do
    include_context 'custom session'

    before do
      allow(ActiveSession).to receive(:list_sessions).with(user).and_return([session])
    end

    shared_examples 'admin mode cannot be enabled' do
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

    describe '#admin_mode?' do
      context 'when the user is a regular user' do
        it_behaves_like 'admin mode cannot be enabled'

        context 'bypassing session' do
          it_behaves_like 'admin mode cannot be enabled' do
            around do |example|
              described_class.bypass_session!(user.id) { example.run }
            end
          end
        end
      end

      context 'when the user is an admin' do
        let(:user) { build_stubbed(:user, :admin) }

        it_behaves_like 'admin_mode? check if admin_mode can be enabled'
      end
    end

    describe '#enable_admin_mode!' do
      context 'when the user is an admin' do
        let(:user) { build_stubbed(:user, :admin) }

        it_behaves_like 'enabling admin_mode when it can be enabled'
      end

      context 'when user is not an admin' do
        let(:user) { build_stubbed(:user) }

        it 'returns false' do
          subject.request_admin_mode!

          expect(subject.enable_admin_mode!(password: user.password)).to eq(false)
        end
      end
    end

    describe '#disable_admin_mode!' do
      let(:user) { build_stubbed(:user, :admin) }

      it_behaves_like 'disabling admin_mode'
    end

    describe '.with_current_request_admin_mode' do
      context 'with a regular user' do
        it 'user is not available inside nor outside the yielded block' do
          described_class.with_current_admin(user) do
            expect(described_class.current_admin).to be_nil
          end

          expect(described_class.bypass_session_admin_id).to be_nil
        end
      end

      context 'with an admin user' do
        let(:user) { build_stubbed(:user, :admin) }

        context 'admin mode is disabled' do
          it 'user is not available inside nor outside the yielded block' do
            described_class.with_current_admin(user) do
              expect(described_class.current_admin).to be_nil
            end

            expect(described_class.bypass_session_admin_id).to be_nil
          end
        end

        context 'admin mode is enabled' do
          before do
            subject.request_admin_mode!
            subject.enable_admin_mode!(password: user.password)
          end

          it 'user is available only inside the yielded block' do
            described_class.with_current_admin(user) do
              expect(described_class.current_admin).to be(user)
            end

            expect(described_class.current_admin).to be_nil
          end
        end
      end
    end
  end

  context 'when no session available' do
    around do |example|
      Gitlab::Session.with_session(nil) do
        example.run
      end
    end

    describe '.bypass_session!' do
      context 'when providing a block' do
        context 'with a regular user' do
          it 'admin mode is false' do
            described_class.bypass_session!(user.id) do
              expect(Gitlab::Session.current).to be_nil
              expect(subject.admin_mode?).to be(false)
              expect(described_class.bypass_session_admin_id).to be(user.id)
            end

            expect(described_class.bypass_session_admin_id).to be_nil
          end
        end

        context 'with an admin user' do
          let(:user) { build_stubbed(:user, :admin) }

          it 'admin mode is true' do
            described_class.bypass_session!(user.id) do
              expect(Gitlab::Session.current).to be_nil
              expect(subject.admin_mode?).to be(true)
              expect(described_class.bypass_session_admin_id).to be(user.id)
            end

            expect(described_class.bypass_session_admin_id).to be_nil
          end
        end
      end

      context 'when not providing a block' do
        context 'with a regular user' do
          it 'admin mode is false' do
            described_class.bypass_session!(user.id)

            expect(Gitlab::Session.current).to be_nil
            expect(subject.admin_mode?).to be(false)
            expect(described_class.bypass_session_admin_id).to be(user.id)

            described_class.reset_bypass_session!

            expect(described_class.bypass_session_admin_id).to be_nil
          end
        end

        context 'with an admin user' do
          let(:user) { build_stubbed(:user, :admin) }

          it 'admin mode is true' do
            described_class.bypass_session!(user.id)

            expect(Gitlab::Session.current).to be_nil
            expect(subject.admin_mode?).to be(true)
            expect(described_class.bypass_session_admin_id).to be(user.id)

            described_class.reset_bypass_session!

            expect(described_class.bypass_session_admin_id).to be_nil
          end
        end
      end
    end

    describe '.optionally_run_in_admin_mode' do
      let(:admin) { build_stubbed(:admin) }

      context 'when invoked from a sidekiq context', :with_sidekiq_context do
        before do
          stub_application_setting(admin_mode: true)
        end

        it 'yields without changing the admin mode for non-admin users' do
          expect { |b| described_class.optionally_run_in_admin_mode(user, &b) }.to yield_control
          expect(described_class.bypass_session_admin_id).to be_nil
        end

        it 'runs in admin mode for admin users' do
          described_class.optionally_run_in_admin_mode(admin) do
            expect(described_class.bypass_session_admin_id).to eq(admin.id)
          end
        end

        it 'resets the admin mode after yielding for admin users' do
          described_class.optionally_run_in_admin_mode(admin) { -> {} }
          expect(described_class.bypass_session_admin_id).to be_nil
        end
      end

      context 'when invoked from a non-sidekiq context' do
        it 'raises an exception' do
          expect { described_class.optionally_run_in_admin_mode(admin) }
            .to raise_error(Gitlab::Auth::CurrentUserMode::NonSidekiqEnvironmentError)
        end
      end
    end
  end
end
