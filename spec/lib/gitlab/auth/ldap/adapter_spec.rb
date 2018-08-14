require 'spec_helper'

describe Gitlab::Auth::LDAP::Adapter do
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
        expect(arg[:attributes]).to match(ldap_attributes)
      end.and_return({})

      adapter.users('uid', 'johndoe')
    end

    it 'searches with the proper options when searching by dn' do
      expect(adapter).to receive(:ldap_search).with(
        base: 'uid=johndoe,ou=users,dc=example,dc=com',
        scope: Net::LDAP::SearchScope_BaseObject,
        attributes: ldap_attributes,
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
        hash_including(attributes: ldap_attributes)
      ).and_return({})

      adapter.users('sAMAccountName', 'johndoe')
    end
  end

  describe '#dn_matches_filter?' do
    subject { adapter.dn_matches_filter?(:dn, :filter) }

    context "when the search result is non-empty" do
      before do
        allow(adapter).to receive(:ldap_search).and_return([:foo])
      end

      it { is_expected.to be_truthy }
    end

    context "when the search result is empty" do
      before do
        allow(adapter).to receive(:ldap_search).and_return([])
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#ldap_search' do
    subject { adapter.ldap_search(base: :dn, filter: :filter) }

    context "when the search is successful" do
      context "and the result is non-empty" do
        before do
          allow(ldap).to receive(:search).and_return([:foo])
        end

        it { is_expected.to eq [:foo] }
      end

      context "and the result is empty" do
        before do
          allow(ldap).to receive(:search).and_return([])
        end

        it { is_expected.to eq [] }
      end
    end

    context "when the search encounters an error" do
      before do
        allow(ldap).to receive_messages(
          search: nil,
          get_operation_result: double(code: 1, message: 'some error')
        )
      end

      it { is_expected.to eq [] }
    end

    context "when the search raises an LDAP exception" do
      before do
        allow(adapter).to receive(:renew_connection_adapter).and_return(ldap)
        allow(ldap).to receive(:search) { raise Net::LDAP::Error, "some error" }
        allow(Rails.logger).to receive(:warn)
      end

      context 'retries the operation' do
        before do
          stub_const("#{described_class}::MAX_SEARCH_RETRIES", 3)
        end

        it 'as many times as MAX_SEARCH_RETRIES' do
          expect(ldap).to receive(:search).exactly(3).times
          expect { subject }.to raise_error(Gitlab::Auth::LDAP::LDAPConnectionError)
        end

        context 'when no more retries' do
          before do
            stub_const("#{described_class}::MAX_SEARCH_RETRIES", 1)
          end

          it 'raises the exception' do
            expect { subject }.to raise_error(Gitlab::Auth::LDAP::LDAPConnectionError)
          end

          it 'logs the error' do
            expect { subject }.to raise_error(Gitlab::Auth::LDAP::LDAPConnectionError)
            expect(Rails.logger).to have_received(:warn).with(
              "LDAP search raised exception Net::LDAP::Error: some error")
          end
        end
      end
    end
  end

  def ldap_attributes
    Gitlab::Auth::LDAP::Person.ldap_attributes(Gitlab::Auth::LDAP::Config.new('ldapmain'))
  end
end
