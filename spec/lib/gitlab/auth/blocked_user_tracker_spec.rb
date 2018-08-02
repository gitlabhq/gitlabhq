require 'spec_helper'

describe Gitlab::Auth::BlockedUserTracker do
  set(:user) { create(:user) }

  describe '#log_blocked_user_activity!' do
    it 'does not log if user failed to login due to undefined reason' do
      expect_any_instance_of(SystemHooksService).not_to receive(:execute_hooks_for)

      tracker = described_class.new({})

      expect(tracker.user).to be_nil
      expect(tracker.user_blocked?).to be_falsey
      expect(tracker.log_blocked_user_activity!).to be_nil
    end

    it 'gracefully handles malformed environment variables' do
      tracker = described_class.new({ 'warden.options' => 'test' })

      expect(tracker.user).to be_nil
      expect(tracker.user_blocked?).to be_falsey
      expect(tracker.log_blocked_user_activity!).to be_nil
    end

    context 'failed login due to blocked user' do
      let(:base_env) { { 'warden.options' => { message: User::BLOCKED_MESSAGE } } }
      let(:env) { base_env.merge(request_env) }

      subject { described_class.new(env) }

      before do
        expect_any_instance_of(SystemHooksService).to receive(:execute_hooks_for).with(user, :failed_login)
      end

      context 'via GitLab login' do
        let(:request_env) { { described_class::ACTIVE_RECORD_REQUEST_PARAMS => { 'user' => { 'login' => user.username } } } }

        it 'logs a blocked user' do
          user.block!

          expect(subject.user).to be_blocked
          expect(subject.user_blocked?).to be true
          expect(subject.log_blocked_user_activity!).to be_truthy
        end

        it 'logs a blocked user by e-mail' do
          user.block!
          env[described_class::ACTIVE_RECORD_REQUEST_PARAMS]['user']['login'] = user.email

          expect(subject.user).to be_blocked
          expect(subject.log_blocked_user_activity!).to be_truthy
        end
      end

      context 'via LDAP login' do
        let(:request_env) { { described_class::ACTIVE_RECORD_REQUEST_PARAMS => { 'username' => user.username } } }

        it 'logs a blocked user' do
          user.block!

          expect(subject.user).to be_blocked
          expect(subject.user_blocked?).to be true
          expect(subject.log_blocked_user_activity!).to be_truthy
        end

        it 'logs a LDAP blocked user' do
          user.ldap_block!

          expect(subject.user).to be_blocked
          expect(subject.user_blocked?).to be true
          expect(subject.log_blocked_user_activity!).to be_truthy
        end
      end
    end
  end
end
