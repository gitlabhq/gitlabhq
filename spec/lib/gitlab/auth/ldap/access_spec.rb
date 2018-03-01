require 'spec_helper'

describe Gitlab::Auth::LDAP::Access do
  let(:access) { described_class.new user }
  let(:user) { create(:omniauth_user) }

  describe '.allowed?' do
    it 'updates the users `last_credential_check_at' do
      expect(access).to receive(:allowed?) { true }
      expect(described_class).to receive(:open).and_yield(access)

      expect { described_class.allowed?(user) }
        .to change { user.last_credential_check_at }
    end
  end

  describe '#allowed?' do
    subject { access.allowed? }

    context 'when the user cannot be found' do
      before do
        allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(nil)
      end

      it { is_expected.to be_falsey }

      it 'blocks user in GitLab' do
        expect(access).to receive(:block_user).with(user, 'does not exist anymore')

        access.allowed?
      end
    end

    context 'when the user is found' do
      before do
        allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(:ldap_user)
      end

      context 'and the user is disabled via active directory' do
        before do
          allow(Gitlab::Auth::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(true)
        end

        it { is_expected.to be_falsey }

        it 'blocks user in GitLab' do
          expect(access).to receive(:block_user).with(user, 'is disabled in Active Directory')

          access.allowed?
        end
      end

      context 'and has no disabled flag in active diretory' do
        before do
          allow(Gitlab::Auth::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(false)
        end

        it { is_expected.to be_truthy }

        context 'when auto-created users are blocked' do
          before do
            user.block
          end

          it 'does not unblock user in GitLab' do
            expect(access).not_to receive(:unblock_user)

            access.allowed?

            expect(user).to be_blocked
            expect(user).not_to be_ldap_blocked # this block is handled by omniauth not by our internal logic
          end
        end

        context 'when auto-created users are not blocked' do
          before do
            user.ldap_block
          end

          it 'unblocks user in GitLab' do
            expect(access).to receive(:unblock_user).with(user, 'is not disabled anymore')

            access.allowed?
          end
        end
      end

      context 'without ActiveDirectory enabled' do
        before do
          allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
          allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive(:active_directory).and_return(false)
        end

        it { is_expected.to be_truthy }

        context 'when user cannot be found' do
          before do
            allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(nil)
          end

          it { is_expected.to be_falsey }

          it 'blocks user in GitLab' do
            expect(access).to receive(:block_user).with(user, 'does not exist anymore')

            access.allowed?
          end
        end

        context 'when user was previously ldap_blocked' do
          before do
            user.ldap_block
          end

          it 'unblocks the user if it exists' do
            expect(access).to receive(:unblock_user).with(user, 'is available again')

            access.allowed?
          end
        end
      end
    end
  end

  describe '#block_user' do
    before do
      user.activate
      allow(Gitlab::AppLogger).to receive(:info)

      access.block_user user, 'reason'
    end

    it 'blocks the user' do
      expect(user).to be_blocked
      expect(user).to be_ldap_blocked
    end

    it 'logs the reason' do
      expect(Gitlab::AppLogger).to have_received(:info).with(
        "LDAP account \"123456\" reason, " \
        "blocking Gitlab user \"#{user.name}\" (#{user.email})"
      )
    end
  end

  describe '#unblock_user' do
    before do
      user.ldap_block
      allow(Gitlab::AppLogger).to receive(:info)

      access.unblock_user user, 'reason'
    end

    it 'activates the user' do
      expect(user).not_to be_blocked
      expect(user).not_to be_ldap_blocked
    end

    it 'logs the reason' do
      Gitlab::AppLogger.info(
        "LDAP account \"123456\" reason, " \
        "unblocking Gitlab user \"#{user.name}\" (#{user.email})"
      )
    end
  end
end
