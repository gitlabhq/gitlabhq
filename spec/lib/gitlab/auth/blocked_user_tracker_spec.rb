require 'spec_helper'

describe Gitlab::Auth::BlockedUserTracker do
  set(:user) { create(:user) }

  describe '.log_if_user_blocked' do
    it 'does not log if user failed to login due to undefined reason' do
      expect_any_instance_of(SystemHooksService).not_to receive(:execute_hooks_for)

      expect(described_class.log_if_user_blocked({})).to be_nil
    end

    it 'gracefully handles malformed environment variables' do
      env = { 'warden.options' => 'test' }

      expect(described_class.log_if_user_blocked(env)).to be_nil
    end

    context 'failed login due to blocked user' do
      let(:env) do
        {
          'warden.options' => { message: User::BLOCKED_MESSAGE },
          described_class::ACTIVE_RECORD_REQUEST_PARAMS => { 'user' => { 'login' => user.username } }
        }
      end

      subject { described_class.log_if_user_blocked(env) }

      before do
        expect_any_instance_of(SystemHooksService).to receive(:execute_hooks_for).with(user, :failed_login)
      end

      it 'logs a blocked user' do
        user.block!

        expect(subject).to be_truthy
      end

      it 'logs a blocked user by e-mail' do
        user.block!
        env[described_class::ACTIVE_RECORD_REQUEST_PARAMS]['user']['login'] = user.email

        expect(subject).to be_truthy
      end

      it 'logs a LDAP blocked user' do
        user.ldap_block!

        expect(subject).to be_truthy
      end
    end
  end
end
