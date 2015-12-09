require 'spec_helper'

describe Gitlab::LDAP::Adapter, lib: true do
  let(:adapter) { Gitlab::LDAP::Adapter.new 'ldapmain' }

  describe '#dn_matches_filter?' do
    let(:ldap) { double(:ldap) }
    subject { adapter.dn_matches_filter?(:dn, :filter) }
    before { allow(adapter).to receive(:ldap).and_return(ldap) }

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
