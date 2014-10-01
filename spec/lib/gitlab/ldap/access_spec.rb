require 'spec_helper'

describe Gitlab::LDAP::Access do
  let(:access) { Gitlab::LDAP::Access.new }
  let(:user) { create(:user) }

  describe :allowed? do
    subject { access.allowed?(user) }

    context 'when the user cannot be found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: nil) }

      it { should be_false }
    end

    context 'when the user is found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: :ldap_user) }

      context 'and the user is diabled via active directory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: true) }

        it { should be_false }
      end

      context 'and has no disabled flag in active diretory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: false) }

        it { should be_true }
      end

      context 'and has no disabled flag in active diretory' do
        before {
          Gitlab::LDAP::Person.stub(disabled_via_active_directory?: false)
          Gitlab.config.ldap['enabled'] = true
          Gitlab.config.ldap['active_directory'] = false
        }

        after {
          Gitlab.config.ldap['enabled'] = false
          Gitlab.config.ldap['active_directory'] = true
        }

        it { should be_false }
      end
    end
  end
end
