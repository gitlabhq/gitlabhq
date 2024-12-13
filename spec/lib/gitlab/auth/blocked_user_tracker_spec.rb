# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::BlockedUserTracker do
  describe '#log_blocked_user_activity!' do
    context 'when user is not blocked' do
      it 'does not log blocked user activity' do
        expect_any_instance_of(SystemHooksService)
          .not_to receive(:execute_hooks_for)
        expect(Gitlab::AppLogger).not_to receive(:info).with(/Failed login for blocked user/)

        user = create(:user)

        described_class.new(user, spy('auth')).log_activity!
      end
    end

    context 'when user is not blocked' do
      it 'logs blocked user activity' do
        allow(Gitlab::AppLogger).to receive(:info)

        user = create(:user, :blocked)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
          .with(user, :failed_login)
        expect(Gitlab::AppLogger).to receive(:info)
          .with(/Failed login for blocked user/)

        described_class.new(user, spy('auth')).log_activity!
      end
    end
  end
end
