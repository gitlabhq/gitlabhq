require 'spec_helper'

describe Gitlab::LDAP::Access, lib: true do
  let(:access) { Gitlab::LDAP::Access.new user }
  let(:user) { create(:omniauth_user) }

  describe :allowed? do
    subject { access.allowed? }

    context 'when the user cannot be found' do
      before do
        allow(Gitlab::LDAP::Person).to receive(:find_by_dn).and_return(nil)
      end

      it { is_expected.to be_falsey }

      it 'should block user in GitLab' do
        access.allowed?
        expect(user).to be_blocked
        expect(user).to be_ldap_blocked
      end
    end

    context 'when the user is found' do
      before do
        allow(Gitlab::LDAP::Person).to receive(:find_by_dn).and_return(:ldap_user)
      end

      context 'and the user is disabled via active directory' do
        before do
          allow(Gitlab::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(true)
        end

        it { is_expected.to be_falsey }

        it 'should block user in GitLab' do
          access.allowed?
          expect(user).to be_blocked
          expect(user).to be_ldap_blocked
        end
      end

      context 'and has no disabled flag in active diretory' do
        before do
          allow(Gitlab::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(false)
        end

        it { is_expected.to be_truthy }

        context 'when auto-created users are blocked' do
          before do
            user.block
          end

          it 'does not unblock user in GitLab' do
            access.allowed?
            expect(user).to be_blocked
            expect(user).not_to be_ldap_blocked # this block is handled by omniauth not by our internal logic
          end
        end

        context 'when auto-created users are not blocked' do
          before do
            user.ldap_block
          end

          it 'should unblock user in GitLab' do
            access.allowed?
            expect(user).not_to be_blocked
          end
        end
      end

      context 'without ActiveDirectory enabled' do
        before do
          allow(Gitlab::LDAP::Config).to receive(:enabled?).and_return(true)
          allow_any_instance_of(Gitlab::LDAP::Config).to receive(:active_directory).and_return(false)
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
