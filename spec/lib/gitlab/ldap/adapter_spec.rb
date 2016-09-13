require 'spec_helper'

describe Gitlab::LDAP::Adapter, lib: true do
  include LdapHelpers

  let(:ldap) { double(:ldap) }
  let(:adapter) { ldap_adapter('ldapmain', ldap) }

  describe '#users' do
    before do
      stub_ldap_config(base: 'dc=example,dc=com')
    end

    it 'searches with the proper options when searching by uid' do
      # Requires this expectation style to match the filter
      expect(adapter).to receive(:ldap_search) do |arg|
        expect(arg[:filter].to_s).to eq('(uid=johndoe)')
        expect(arg[:base]).to eq('dc=example,dc=com')
        expect(arg[:attributes]).to match(%w{uid cn mail dn})
      end.and_return({})

      adapter.users('uid', 'johndoe')
    end

    it 'searches with the proper options when searching by dn' do
      expect(adapter).to receive(:ldap_search).with(
        base: 'uid=johndoe,ou=users,dc=example,dc=com',
        scope: Net::LDAP::SearchScope_BaseObject,
        attributes: %w{uid cn mail dn},
        filter: nil
      ).and_return({})

      adapter.users('dn', 'uid=johndoe,ou=users,dc=example,dc=com')
    end

    it 'searches with the proper options when searching with a limit' do
      expect(adapter)
        .to receive(:ldap_search).with(hash_including(size: 100)).and_return({})

      adapter.users('uid', 'johndoe', 100)
    end

    it 'returns an LDAP::Person if search returns a result' do
      entry = ldap_user_entry('johndoe')
      allow(adapter).to receive(:ldap_search).and_return([entry])

      results = adapter.users('uid', 'johndoe')

      expect(results.size).to eq(1)
      expect(results.first.uid).to eq('johndoe')
    end

    it 'returns empty array if search entry does not respond to uid' do
      entry = Net::LDAP::Entry.new
      entry['dn'] = user_dn('johndoe')
      allow(adapter).to receive(:ldap_search).and_return([entry])

      results = adapter.users('uid', 'johndoe')

      expect(results).to be_empty
    end

    it 'uses the right uid attribute when non-default' do
      stub_ldap_config(uid: 'sAMAccountName')
      expect(adapter).to receive(:ldap_search).with(
        hash_including(attributes: %w{sAMAccountName cn mail dn})
      ).and_return({})

      adapter.users('sAMAccountName', 'johndoe')
    end
  end

  describe '#dn_matches_filter?' do
    subject { adapter.dn_matches_filter?(:dn, :filter) }

    context "when the search is successful" do
      context "and the result is non-empty" do
        before { allow(ldap).to receive(:search).and_return([:foo]) }

        it { is_expected.to be_truthy }
      end

      context "and the result is empty" do
        before { allow(ldap).to receive(:search).and_return([]) }

        it { is_expected.to be_falsey }
      end
    end

    context "when the search encounters an error" do
      before do
        allow(ldap).to receive_messages(
          search: nil,
          get_operation_result: double(code: 1, message: 'some error')
        )
      end

      it { is_expected.to be_falsey }
    end
  end
end
