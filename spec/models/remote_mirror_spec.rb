require 'rails_helper'

describe RemoteMirror do
  describe 'URL validation' do
    context 'with a valid URL' do
      it 'should be valid' do
        remote_mirror = build(:remote_mirror)
        expect(remote_mirror).to be_valid
      end
    end

    context 'with an invalid URL' do
      it 'should not be valid' do
        remote_mirror = build(:remote_mirror, url: 'ftp://invalid.invalid')
        expect(remote_mirror).not_to be_valid
        expect(remote_mirror.errors[:url].size).to eq(2)
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

        config = repo.raw_repository.rugged.config
        expect(config["remote.#{mirror.remote_name}.url"]).to eq('http://foo:baz@test.com')
      end

      it 'removes previous remote' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(RepositoryRemoveRemoteWorker).to receive(:perform_async).with(mirror.project.id, mirror.remote_name).and_call_original

        mirror.update_attributes(url: 'http://test.com')
      end
    end
  end

  describe '#remote_name' do
    context 'when remote name is persisted in the database' do
      it 'returns remote name with random value' do
        allow(SecureRandom).to receive(:hex).and_return('secret')

        remote_mirror = create(:remote_mirror)

        expect(remote_mirror.remote_name).to eq("remote_mirror_secret")
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

  context 'when remote mirror gets destroyed' do
    it 'removes remote' do
      mirror = create_mirror(url: 'http://foo:bar@test.com')

      expect(RepositoryRemoveRemoteWorker).to receive(:perform_async).with(mirror.project.id, mirror.remote_name).and_call_original

      mirror.destroy!
    end
  end

  context 'stuck mirrors' do
    it 'includes mirrors stuck in started with no last_update_at set' do
      mirror = create_mirror(url: 'http://cantbeblank',
                             update_status: 'started',
                             last_update_at: nil,
                             updated_at: 25.hours.ago)

      expect(described_class.stuck.last).to eq(mirror)
    end
  end

  context '#sync' do
    let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'with remote mirroring disabled' do
      it 'returns nil' do
        remote_mirror.update_attributes(enabled: false)

        expect(remote_mirror.sync).to be_nil
      end
    end

    context 'as a Geo secondary' do
      it 'returns nil' do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)

        expect(remote_mirror.sync).to be_nil
      end
    end

    context 'with remote mirroring enabled' do
      context 'with only protected branches enabled' do
        context 'when it did not update in the last minute' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run now' do
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(remote_mirror.id, Time.now)

            remote_mirror.sync
          end
        end

        context 'when it did update in the last minute' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run in the next minute' do
            remote_mirror.last_update_started_at = Time.now - 30.seconds

            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_in).with(RemoteMirror::PROTECTED_BACKOFF_DELAY, remote_mirror.id, Time.now)

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
            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_async).with(remote_mirror.id, Time.now)

            remote_mirror.sync
          end
        end

        context 'when it did update within the last 5 minutes' do
          it 'schedules a RepositoryUpdateRemoteMirrorWorker to run in the next 5 minutes' do
            remote_mirror.last_update_started_at = Time.now - 30.seconds

            expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_in).with(RemoteMirror::UNPROTECTED_BACKOFF_DELAY, remote_mirror.id, Time.now)

            remote_mirror.sync
          end
        end
      end
    end
  end

  context '#updated_since?' do
    let(:remote_mirror) { create(:project, :repository, :remote_mirror).remote_mirrors.first }
    let(:timestamp) { Time.now - 5.minutes }

    around do |example|
      Timecop.freeze { example.run }
    end

    before do
      remote_mirror.update_attributes(last_update_started_at: Time.now)
    end

    context 'when remote mirror does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(remote_mirror.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(remote_mirror.updated_since?(Time.now + 5.minutes)).to be false
      end
    end

    context 'when remote mirror has status failed' do
      it 'returns false when last update started after the timestamp' do
        remote_mirror.update_attributes(update_status: 'failed')

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

  def create_mirror(params)
    project = FactoryBot.create(:project, :repository)
    project.remote_mirrors.create!(params)
  end
end
