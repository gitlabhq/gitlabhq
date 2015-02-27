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

      context 'and the user is diabled via active directory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: true) }

        it { is_expected.to be_falsey }
      end

      context 'and has no disabled flag in active diretory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: false) }

        it { is_expected.to be_truthy }
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