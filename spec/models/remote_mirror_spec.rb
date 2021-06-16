# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirror, :mailer do
  include GitHelpers

  describe 'URL validation' do
    context 'with a valid URL' do
      it 'is valid' do
        remote_mirror = build(:remote_mirror)
        expect(remote_mirror).to be_valid
      end
    end

    context 'with an invalid URL' do
      it 'is not valid' do
        remote_mirror = build(:remote_mirror, url: 'ftp://invalid.invalid')

        expect(remote_mirror).not_to be_valid
      end

      it 'does not allow url with an invalid user' do
        remote_mirror = build(:remote_mirror, url: 'http://$user:password@invalid.invalid')

        expect(remote_mirror).to be_invalid
        expect(remote_mirror.errors[:url].first).to include('Username needs to start with an alphanumeric character')
      end

      it 'does not allow url pointing to localhost' do
        remote_mirror = build(:remote_mirror, url: 'http://127.0.0.2/t.git')

        expect(remote_mirror).to be_invalid
        expect(remote_mirror.errors[:url].first).to include('Requests to loopback addresses are not allowed')
      end

      it 'does not allow url pointing to the local network' do
        remote_mirror = build(:remote_mirror, url: 'https://192.168.1.1')

        expect(remote_mirror).to be_invalid
        expect(remote_mirror.errors[:url].first).to include('Requests to the local network are not allowed')
      end

      it 'returns a nil safe_url' do
        remote_mirror = build(:remote_mirror, url: 'http://[0:0:0:0:ffff:123.123.123.123]/foo.git')

        expect(remote_mirror.url).to eq('http://[0:0:0:0:ffff:123.123.123.123]/foo.git')
        expect(remote_mirror.safe_url).to be_nil
      end
    end
  end

  describe 'encrypting credentials' do
    context 'when setting URL for a first time' do
      it 'stores the URL without credentials' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(mirror.read_attribute(:url)).to eq('http://test.com')
      end

      it 'stores the credentials on a separate field' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(mirror.credentials).to eq({ user: 'foo', password: 'bar' })
      end

      it 'handles credentials with large content' do
        mirror = create_mirror(url: 'http://bxnhm8dote33ct932r3xavslj81wxmr7o8yux8do10oozckkif:9ne7fuvjn40qjt35dgt8v86q9m9g9essryxj76sumg2ccl2fg26c0krtz2gzfpyq4hf22h328uhq6npuiq6h53tpagtsj7vsrz75@test.com')

        expect(mirror.credentials).to eq({
          user: 'bxnhm8dote33ct932r3xavslj81wxmr7o8yux8do10oozckkif',
          password: '9ne7fuvjn40qjt35dgt8v86q9m9g9essryxj76sumg2ccl2fg26c0krtz2gzfpyq4hf22h328uhq6npuiq6h53tpagtsj7vsrz75'
        })
      end
    end

    context 'when updating the URL' do
      it 'allows a new URL without credentials' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        mirror.update_attribute(:url, 'http://test.com')

        expect(mirror.url).to eq('http://test.com')
        expect(mirror.credentials).to eq({ user: nil, password: nil })
      end

      it 'allows a new URL with credentials' do
        mirror = create_mirror(url: 'http://test.com')

        mirror.update_attribute(:url, 'http://foo:bar@test.com')

        expect(mirror.url).to eq('http://foo:bar@test.com')
        expect(mirror.credentials).to eq({ user: 'foo', password: 'bar' })
      end

      it 'updates the remote config if credentials changed' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')
        repo = mirror.project.repository

        mirror.update_attribute(:url, 'http://foo:baz@test.com')

        config = rugged_repo(repo).config
        expect(config["remote.#{mirror.remote_name}.url"]).to eq('http://foo:baz@test.com')
      end

      it 'removes previous remote' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(RepositoryRemoveRemoteWorker).to receive(:perform_async).with(mirror.project.id, mirror.remote_name).and_call_original

        mirror.update(url: 'http://test.com')
      end
    end
  end

  describe '#remote_name' do
    context 'when remote name is persisted in the database' do
      it 'returns remote name with random value' do
        allow(SecureRandom).to receive(:hex).and_return('secret')

        remote_mirror = create(:remote_mirror)

        expect(remote_mirror.remote_name).to eq('remote_mirror_secret')
      end
    end

    context 'when remote name is not persisted in the database' do
      it 'returns remote name with remote mirror id' do
        remote_mirror = create(:remote_mirror)
        remote_mirror.remote_name = nil

        expect(remote_mirror.remote_name).to eq("remote_mirror_#{remote_mirror.id}")
      end
    end

    context 'when remote is not persisted in the database' do
      it 'returns nil' do
        remote_mirror = build(:remote_mirror, remote_name: nil)

        expect(remote_mirror.remote_name).to be_nil
      end
    end
  end

  describe '#bare_url' do
    it 'returns the URL without any credentials' do
      remote_mirror = build(:remote_mirror, url: 'http://user:pass@example.com/foo')

      expect(remote_mirror.bare_url).to eq('http://example.com/foo')
    end

    it 'returns an empty string when the URL is nil' do
      remote_mirror = build(:remote_mirror, url: nil)

      expect(remote_mirror.bare_url).to eq('')
    end
  end

  describe '#update_repository' do
    shared_examples 'an update' do
      it 'performs update including options' do
        git_remote_mirror = stub_const('Gitlab::Git::RemoteMirror', spy)
        mirror = build(:remote_mirror)

        expect(mirror).to receive(:options_for_update).and_return(keep_divergent_refs: true)
        mirror.update_repository(inmemory_remote: inmemory)

        expect(git_remote_mirror).to have_received(:new).with(
          mirror.project.repository.raw,
          mirror.remote_name,
          inmemory ? mirror.url : nil,
          keep_divergent_refs: true
        )
        expect(git_remote_mirror).to have_received(:update)
      end
    end

    context 'with inmemory remote' do
      let(:inmemory) { true }

      it_behaves_like 'an update'
    end

    context 'with on-disk remote' do
      let(:inmemory) { false }

      it_behaves_like 'an update'
    end
  end

  describe '#options_for_update' do
    it 'includes the `keep_divergent_refs` option' do
      mirror = build_stubbed(:remote_mirror, keep_divergent_refs: true)

      options = mirror.options_for_update

      expect(options).to include(keep_divergent_refs: true)
    end

    it 'includes the `only_branches_matching` option' do
      branch = create(:protected_branch)
      mirror = build_stubbed(:remote_mirror, project: branch.project, only_protected_branches: true)

      options = mirror.options_for_update

      expect(options).to include(only_branches_matching: [branch.name])
    end

    it 'includes the `ssh_key` option' do
      mirror = build(:remote_mirror, :ssh, ssh_private_key: 'private-key')

      options = mirror.options_for_update

      expect(options).to include(ssh_key: 'private-key')
    end

    it 'includes the `known_hosts` option' do
      mirror = build(:remote_mirror, :ssh, ssh_known_hosts: 'known-hosts')

      options = mirror.options_for_update

      expect(options).to include(known_hosts: 'known-hosts')
    end
  end

  describe '#safe_url' do
    context 'when URL contains credentials' do
      it 'masks the credentials' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(mirror.safe_url).to eq('http://*****:*****@test.com')
      end
    end

    context 'when URL does not contain credentials' do
      it 'shows the full URL' do
        mirror = create_mirror(url: 'http://test.com')

        expect(mirror.safe_url).to eq('http://test.com')
      end
    end
  end

  describe '#mark_as_failed!' do
    let(:remote_mirror) { create(:remote_mirror) }
    let(:error_message) { 'http://user:pass@test.com/root/repoC.git/' }
    let(:sanitized_error_message) { 'http://*****:*****@test.com/root/repoC.git/' }

    subject do
      remote_mirror.update_start
      remote_mirror.mark_as_failed!(error_message)
    end

    it 'sets the update_status to failed' do
      subject

      expect(remote_mirror.reload.update_status).to eq('failed')
    end

    it 'saves the sanitized error' do
      subject

      expect(remote_mirror.last_error).to eq(sanitized_error_message)
    end

    context 'notifications' do
      let(:user) { create(:user) }

      before do
        remote_mirror.project.add_maintainer(user)
      end

      it 'notifies the project maintainers', :sidekiq_might_not_need_inline do
        perform_enqueued_jobs { subject }

        should_email(user)
      end
    end
  end

  describe '#hard_retry!' do
    let(:remote_mirror) { create(:remote_mirror).tap {|mirror| mirror.update_column(:url, 'invalid') } }

    it 'transitions an invalid mirror to the to_retry state' do
      remote_mirror.hard_retry!('Invalid')

      expect(remote_mirror.update_status).to eq('to_retry')
      expect(remote_mirror.last_error).to eq('Invalid')
    end
  end

  describe '#hard_fail!' do
    let(:remote_mirror) { create(:remote_mirror).tap {|mirror| mirror.update_column(:url, 'invalid') } }

    it 'transitions an invalid mirror to the failed state' do
      remote_mirror.hard_fail!('Invalid')

      expect(remote_mirror.update_status).to eq('failed')
      expect(remote_mirror.last_error).to eq('Invalid')
      expect(remote_mirror.last_update_at).not_to be_nil
      expect(RemoteMirrorNotificationWorker.jobs).not_to be_empty
    end
  end

  context 'when remote mirror gets destroyed' do
    it 'removes remote' do
      mirror = create_mirror(url: 'http://foo:bar@test.com')

      expect(RepositoryRemoveRemoteWorker).to receive(:perform_async).with(mirror.project.id, mirror.remote_name).and_call_original

      mirror.destroy!
    end
  end

  context 'stuck mirrors' do
    it 'includes mirrors that were started over an hour ago' do
      mirror = create_mirror(url: 'http://cantbeblank',
                             update_status: 'started',
                             last_update_started_at: 3.hours.ago,
                             last_update_at: 2.hours.ago)

      expect(described_class.stuck.last).to eq(mirror)
    end

    it 'includes mirrors started over 3 hours ago for their first sync' do
      mirror = create_mirror(url: 'http://cantbeblank',
                             update_status: 'started',
                             last_update_at: nil,
                             last_update_started_at: 4.hours.ago)

      expect(described_class.stuck.last).to eq(mirror)
    end
  end

  describe '#sync' do
    let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }

    around do |example|
      freeze_time { example.run }
    end

    context 'with remote mirroring disabled' do
      it 'returns nil' do
        remote_mirror.update(enabled: false)

        expect(remote_mirror.sync).to be_nil
      end
    end

    context 'with remote mirroring enabled' do
      it 'defaults to disabling only protected branches' do
        expect(remote_mirror.only_protected_branches?).to be_falsey
      end

      context 'with only protected branches enabled' do
        before do
          remote_mirror.only_protected_branches = true
        end

        context 'when it did not update in the last minute' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run now' do
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(remote_mirror.id, Time.current)

            remote_mirror.sync
          end
        end

        context 'when it did update in the last minute' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run in the next minute' do
            remote_mirror.last_update_started_at = Time.current - 30.seconds

            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_in).with(RemoteMirror::PROTECTED_BACKOFF_DELAY, remote_mirror.id, Time.current)

            remote_mirror.sync
          end
        end
      end

      context 'with only protected branches disabled' do
        before do
          remote_mirror.only_protected_branches = false
        end

        context 'when it did not update in the last 5 minutes' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run now' do
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(remote_mirror.id, Time.current)

            remote_mirror.sync
          end
        end

        context 'when it did update within the last 5 minutes' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run in the next 5 minutes' do
            remote_mirror.last_update_started_at = Time.current - 30.seconds

            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_in).with(RemoteMirror::UNPROTECTED_BACKOFF_DELAY, remote_mirror.id, Time.current)

            remote_mirror.sync
          end
        end
      end
    end
  end

  describe '#ensure_remote!' do
    let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }
    let(:project) { remote_mirror.project }
    let(:repository) { project.repository }

    it 'adds a remote multiple times with no errors' do
      expect(repository).to receive(:add_remote).with(remote_mirror.remote_name, remote_mirror.url).twice.and_call_original

      2.times do
        remote_mirror.ensure_remote!
      end
    end

    context 'SSH public-key authentication' do
      it 'omits the password from the URL' do
        remote_mirror.update!(auth_method: 'ssh_public_key', url: 'ssh://git:pass@example.com')

        expect(repository).to receive(:add_remote).with(remote_mirror.remote_name, 'ssh://git@example.com')

        remote_mirror.ensure_remote!
      end
    end
  end

  describe '#url=' do
    let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }

    it 'resets all the columns when URL changes' do
      remote_mirror.update(last_error: Time.current,
                           last_update_at: Time.current,
                           last_successful_update_at: Time.current,
                           update_status: 'started',
                           error_notification_sent: true)

      expect { remote_mirror.update_attribute(:url, 'http://new.example.com') }
        .to change { remote_mirror.last_error }.to(nil)
        .and change { remote_mirror.last_update_at }.to(nil)
        .and change { remote_mirror.last_successful_update_at }.to(nil)
        .and change { remote_mirror.update_status }.to('finished')
        .and change { remote_mirror.error_notification_sent }.to(false)
    end
  end

  describe '#updated_since?' do
    let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }
    let(:timestamp) { Time.current - 5.minutes }

    around do |example|
      freeze_time { example.run }
    end

    before do
      remote_mirror.update(last_update_started_at: Time.current)
    end

    context 'when remote mirror does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(remote_mirror.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(remote_mirror.updated_since?(Time.current + 5.minutes)).to be false
      end
    end

    context 'when remote mirror has status failed' do
      it 'returns false when last update started after the timestamp' do
        remote_mirror.update(update_status: 'failed')

        expect(remote_mirror.updated_since?(timestamp)).to be false
      end
    end
  end

  context 'no project' do
    it 'includes mirror with a project in pending_delete' do
      mirror = create_mirror(url: 'http://cantbeblank',
                             update_status: 'finished',
                             enabled: true,
                             last_update_at: nil,
                             updated_at: 25.hours.ago)
      project = mirror.project
      project.pending_delete = true
      project.save
      mirror.reload

      expect(mirror.sync).to be_nil
      expect(mirror.valid?).to be_truthy
      expect(mirror.update_status).to eq('finished')
    end
  end

  describe '#disabled?' do
    let_it_be(:project) { create(:project, :repository) }

    subject { remote_mirror.disabled? }

    context 'when disabled' do
      let(:remote_mirror) { build(:remote_mirror, project: project, enabled: false) }

      it { is_expected.to be_truthy }
    end

    context 'when enabled' do
      let(:remote_mirror) { build(:remote_mirror, project: project, enabled: true) }

      it { is_expected.to be_falsy }
    end
  end

  def create_mirror(params)
    project = FactoryBot.create(:project, :repository)
    project.remote_mirrors.create!(params)
  end
end
