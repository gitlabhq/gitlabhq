require 'spec_helper'

describe Gitlab::LDAP::Access do
  let(:access) { Gitlab::LDAP::Access.new user }
  let(:user) { create(:omniauth_user) }

  describe :allowed? do
    subject { access.allowed? }

    context 'when the user cannot be found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: nil) }

      it { is_expected.to be_falsey }
    end

    context 'when the user is found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: :ldap_user) }

      context 'and the user is disabled via active directory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: true) }

        it { is_expected.to be_falsey }

        it "should block user in GitLab" do
          access.allowed?
          user.should be_blocked
        end
      end

      context 'and has no disabled flag in active diretory' do
        before do
          user.block
          
          Gitlab::LDAP::Person.stub(disabled_via_active_directory?: false)
        end

        it { is_expected.to be_truthy }

        context 'when auto-created users are blocked' do

          before do
            Gitlab::LDAP::Config.any_instance.stub(block_auto_created_users: true)
          end

          it "does not unblock user in GitLab" do
            access.allowed?
            user.should be_blocked
          end
        end

        context "when auto-created users are not blocked" do

          before do
            Gitlab::LDAP::Config.any_instance.stub(block_auto_created_users: false)
          end

          it "should unblock user in GitLab" do
            access.allowed?
            user.should_not be_blocked
          end
        end
      end

      context 'without ActiveDirectory enabled' do
        before do
          Gitlab::LDAP::Config.stub(enabled?: true)
          Gitlab::LDAP::Config.any_instance.stub(active_directory: false)
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
