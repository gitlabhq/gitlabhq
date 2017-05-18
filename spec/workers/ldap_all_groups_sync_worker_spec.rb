require 'spec_helper'

describe LdapAllGroupsSyncWorker do
  let(:subject) { described_class.new }

  before do
    allow(Sidekiq.logger).to receive(:info)
  end

  describe '#perform' do
    it 'syncs all groups when group_id is nil' do
      expect(EE::Gitlab::LDAP::Sync::Groups).to receive(:execute)

      subject.perform
    end
  end
end
