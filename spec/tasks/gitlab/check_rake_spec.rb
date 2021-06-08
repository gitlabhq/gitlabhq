# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'check.rake', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/check'

    stub_warn_user_is_not_gitlab
  end

  shared_examples_for 'system check rake task' do
    it 'runs the check' do
      expect do
        subject
      end.to output(/Checking #{name} ... Finished/).to_stdout
    end
  end

  describe 'gitlab:check rake task' do
    subject { run_rake_task('gitlab:check') }

    let(:name) { 'GitLab subtasks' }

    it_behaves_like 'system check rake task'
  end

  describe 'gitlab:gitlab_shell:check rake task' do
    subject { run_rake_task('gitlab:gitlab_shell:check') }

    let(:name) { 'GitLab Shell' }

    it_behaves_like 'system check rake task'
  end

  describe 'gitlab:gitaly:check rake task' do
    subject { run_rake_task('gitlab:gitaly:check') }

    let(:name) { 'Gitaly' }

    it_behaves_like 'system check rake task'
  end

  describe 'gitlab:sidekiq:check rake task' do
    subject { run_rake_task('gitlab:sidekiq:check') }

    let(:name) { 'Sidekiq' }

    it_behaves_like 'system check rake task'
  end

  describe 'gitlab:incoming_email:check rake task' do
    subject { run_rake_task('gitlab:incoming_email:check') }

    let(:name) { 'Incoming Email' }

    it_behaves_like 'system check rake task'
  end

  describe 'gitlab:ldap:check rake task' do
    include LdapHelpers

    subject { run_rake_task('gitlab:ldap:check') }

    let(:name) { 'LDAP' }

    it_behaves_like 'system check rake task'

    context 'when LDAP is not enabled' do
      it 'does not attempt to bind or search for users' do
        expect(Gitlab::Auth::Ldap::Config).not_to receive(:providers)
        expect(Gitlab::Auth::Ldap::Adapter).not_to receive(:open)

        subject
      end
    end

    context 'when LDAP is enabled' do
      let(:ldap) { double(:ldap) }
      let(:adapter) { ldap_adapter('ldapmain', ldap) }

      before do
        allow(Gitlab::Auth::Ldap::Config)
          .to receive_messages(
            enabled?: true,
            providers: ['ldapmain']
          )
        allow(Gitlab::Auth::Ldap::Adapter).to receive(:open).and_yield(adapter)
        allow(adapter).to receive(:users).and_return([])
      end

      it 'attempts to bind using credentials' do
        stub_ldap_config(has_auth?: true)

        expect(ldap).to receive(:bind)

        subject
      end

      it 'searches for 100 LDAP users' do
        stub_ldap_config(uid: 'uid')

        expect(adapter).to receive(:users).with('uid', '*', 100)

        subject
      end

      it 'sanitizes output' do
        user = double(dn: 'uid=fake_user1', uid: 'fake_user1')
        allow(adapter).to receive(:users).and_return([user])
        stub_env('SANITIZE', 'true')

        expect { subject }.to output(/User output sanitized/).to_stdout
        expect { subject }.not_to output('fake_user1').to_stdout
      end
    end
  end
end
