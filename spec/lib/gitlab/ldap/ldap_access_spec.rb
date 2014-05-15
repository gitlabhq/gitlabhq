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

      context 'and the Active Directory disabled flag is set' do
        before { Gitlab::LDAP::Person.stub(active_directory_disabled?: true) }

        it { should be_false }
      end

      context 'and the Active Directory disabled flag is not set' do
        before { Gitlab::LDAP::Person.stub(active_directory_disabled?: false) }

        it { should be_true }
      end
    end
  end
end
