require 'spec_helper'

describe Gitlab::LDAP::Adapter, lib: true do
  include LdapHelpers

  it 'includes the EE module' do
    expect(Gitlab::LDAP::Adapter).to include_module(EE::Gitlab::LDAP::Adapter)
  end

  let(:adapter) { ldap_adapter('ldapmain') }

  describe '#groups' do
    before do
      stub_ldap_config(
        group_base: 'ou=groups,dc=example,dc=com',
        active_directory: false
      )
    end

    it 'searches with the proper options' do
      # Requires this expectation style to match the filter
      expect(adapter).to receive(:ldap_search) do |arg|
        expect(arg[:filter].to_s).to eq('(cn=*)')
        expect(arg[:base]).to eq('ou=groups,dc=example,dc=com')
        expect(arg[:attributes]).to match(%w(dn cn memberuid member submember uniquemember memberof))
      end.and_return({})

      adapter.groups
    end

    it 'returns a group object if search returns a result' do
      entry = ldap_group_entry(['john', 'mary'], cn: 'group1')
      allow(adapter).to receive(:ldap_search).and_return([entry])

      results = adapter.groups('group1')

      expect(results.first).to be_a(EE::Gitlab::LDAP::Group)
      expect(results.first.cn).to eq('group1')
      expect(results.first.member_dns).to match_array(%w(john mary))
    end
  end

  describe '#user_attributes' do
    it 'appends EE-specific attributes' do
      stub_ldap_config(uid: 'uid', sync_ssh_keys: 'sshPublicKey')
      expect(adapter.user_attributes).to match_array(%w(uid dn cn mail sshPublicKey))
    end
  end
end
