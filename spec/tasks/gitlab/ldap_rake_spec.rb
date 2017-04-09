require 'rake_helper'

describe 'gitlab:ldap:rename_provider rake task' do
  it 'completes without error' do
    Rake.application.rake_require 'tasks/gitlab/ldap'
    stub_warn_user_is_not_gitlab
    ENV['force'] = 'yes'

    create(:identity) # Necessary to prevent `exit 1` from the task.

    run_rake_task('gitlab:ldap:rename_provider', 'ldapmain', 'ldapfoo')
  end
end

describe 'gitlab:ldap:generate_avatars rake task' do
  include LdapHelpers

  before do
    Rake.application.rake_require 'tasks/gitlab/ldap'

    stub_warn_user_is_not_gitlab
  end

  context 'when LDAP is not enabled' do
    it 'does not attempt to bind or search for users' do
      expect(Gitlab::LDAP::Config).not_to receive(:providers)
      expect(Gitlab::LDAP::Adapter).not_to receive(:open)

      run_rake_task('gitlab:ldap:generate_avatars')
    end
  end

  context 'when LDAP is enabled' do
    let(:ldap) { double(:ldap) }
    let(:adapter) { ldap_adapter('ldapmain', ldap) }

    before do
      allow(Gitlab::LDAP::Config)
        .to receive_messages(
          enabled?: true,
          providers: ['ldapmain']
        )
      allow(Gitlab::LDAP::Adapter).to receive(:open).and_yield(adapter)
      allow(adapter).to receive(:users).and_return([])
    end

    it 'attempts to bind using credentials' do
      stub_ldap_config(has_auth?: true)

      expect(ldap).to receive(:bind)

      run_rake_task('gitlab:ldap:generate_avatars')
    end

    it 'searches for all LDAP users' do
      stub_ldap_config(uid: 'uid')

      expect(adapter).to receive(:users).with('uid', '*')

      run_rake_task('gitlab:ldap:generate_avatars')
    end
  end
end
