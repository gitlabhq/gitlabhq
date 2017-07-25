require 'rails_helper'

describe RemoteMirror do
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
        expect(config["remote.#{mirror.ref_name}.url"]).to eq('http://foo:baz@test.com')
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
    let(:remote_mirror) { create(:project, :remote_mirror).remote_mirrors.first }

    before do
      Timecop.freeze(Time.now)
    end

    after do
      Timecop.return
    end

    context 'repository mirrors not licensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not schedule RepositoryUpdateRemoteMirrorWorker' do
        expect(RepositoryUpdateRemoteMirrorWorker).not_to receive(:perform_in)

        remote_mirror.sync
      end
    end

    context 'with remote mirroring enabled' do
      it 'schedules a RepositoryUpdateRemoteMirrorWorker to run within a certain backoff delay' do
        expect(RepositoryUpdateRemoteMirrorWorker).to receive(:perform_in).with(RemoteMirror::BACKOFF_DELAY, remote_mirror.id, Time.now)

        remote_mirror.sync
      end
    end

    context 'with remote mirroring disabled' do
      it 'returns nil' do
        remote_mirror.update_attributes(enabled: false)

        expect(remote_mirror.sync).to be_nil
      end
    end

    context 'without project' do
      it 'returns nil' do
        allow_any_instance_of(described_class).to receive(:project).and_return(nil)

        expect(remote_mirror.sync).to be_nil
      end
    end

    context 'as a Geo secondary' do
      it 'returns nil' do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)

        expect(remote_mirror.sync).to be_nil
      end
    end
  end

  context '#updated_since?' do
    let(:remote_mirror) { create(:project, :remote_mirror).remote_mirrors.first }
    let(:timestamp) { Time.now - 5.minutes }

    before do
      Timecop.freeze(Time.now)
      remote_mirror.update_attributes(last_update_started_at: Time.now)
    end

    after do
      Timecop.return
    end

    context 'when remote mirror does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(remote_mirror.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(remote_mirror.updated_since?(Time.now + 5.minutes)).to be  false
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
    project = FactoryGirl.create(:project)
    project.remote_mirrors.create!(params)
  end
end
