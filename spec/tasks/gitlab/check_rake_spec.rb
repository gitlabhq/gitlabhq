require 'rake_helper'

describe 'gitlab:ldap:check rake task' do
  include LdapHelpers

  before do
    Rake.application.rake_require 'tasks/gitlab/check'

    stub_warn_user_is_not_gitlab
  end

  context 'when LDAP is not enabled' do
    it 'does not attempt to bind or search for users' do
      expect(Gitlab::Auth::LDAP::Config).not_to receive(:providers)
      expect(Gitlab::Auth::LDAP::Adapter).not_to receive(:open)

      run_rake_task('gitlab:ldap:check')
    end
  end

  context 'when LDAP is enabled' do
    let(:ldap) { double(:ldap) }
    let(:adapter) { ldap_adapter('ldapmain', ldap) }

    before do
      allow(Gitlab::Auth::LDAP::Config)
        .to receive_messages(
          enabled?: true,
          providers: ['ldapmain']
        )
      allow(Gitlab::Auth::LDAP::Adapter).to receive(:open).and_yield(adapter)
      allow(adapter).to receive(:users).and_return([])
    end

    it 'attempts to bind using credentials' do
      stub_ldap_config(has_auth?: true)

      expect(ldap).to receive(:bind)

      run_rake_task('gitlab:ldap:check')
    end

    it 'searches for 100 LDAP users' do
      stub_ldap_config(uid: 'uid')

      expect(adapter).to receive(:users).with('uid', '*', 100)

      run_rake_task('gitlab:ldap:check')
    end
  end
end
