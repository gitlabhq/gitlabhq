require 'spec_helper'

describe GeoNode, type: :model do
  subject(:new_node) { described_class.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }
  subject(:new_primary_node) { described_class.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab', primary: true) }
  subject(:empty_node) { described_class.new }
  subject(:primary_node) { FactoryGirl.create(:geo_node, :primary) }
  subject(:node) { FactoryGirl.create(:geo_node) }

  let(:dummy_url) { 'https://localhost:3000/gitlab' }
  let(:url_helpers) { Gitlab::Application.routes.url_helpers }

  context 'associations' do
    it { is_expected.to belong_to(:geo_node_key).dependent(:destroy) }
    it { is_expected.to belong_to(:oauth_application).dependent(:destroy) }
  end

  context 'default values' do
    let(:gitlab_host) { 'gitlabhost' }
    before(:each) { allow(Gitlab.config.gitlab).to receive(:host) { gitlab_host } }
    subject { described_class.new }

    it 'defines a default schema' do
      expect(subject.schema).to eq('http')
    end

    it 'defines a default host' do
      expect(subject.host).to eq(gitlab_host)
    end

    it 'defines a default port' do
      expect(subject.port).to eq(80)
    end

    it 'defines a default relative_url_root' do
      expect(subject.relative_url_root).to eq('')
    end

    it 'defines a default primary flag' do
      expect(subject.primary).to eq(false)
    end
  end

  context 'prevent locking yourself out' do
    subject do
      GeoNode.new(host: Gitlab.config.gitlab.host,
                  port: Gitlab.config.gitlab.port,
                  relative_url_root: Gitlab.config.gitlab.relative_url_root)
    end

    it 'does not accept adding a non primary node with same details as current_node' do
      expect(subject).not_to be_valid
    end
  end

  context 'dependent models for GeoNode' do
    let(:geo_node_key_attributes) { FactoryGirl.build(:geo_node_key).attributes }

    context 'on initialize' do
      it 'initializes a corresponding key' do
        expect(new_node.geo_node_key).to be_present
      end

      it 'is valid when required attributes are present' do
        new_node.geo_node_key_attributes = geo_node_key_attributes
        expect(new_node).to be_valid
      end
    end

    context 'on create' do
      it 'saves a corresponding key' do
        expect(node.geo_node_key).to be_persisted
      end

      it 'saves a corresponding oauth application if it is a secondary node' do
        expect(node.oauth_application).to be_persisted
      end

      it 'has no oauth_application if it is a primary node' do
        expect(primary_node.oauth_application).not_to be_present
      end

      it 'has a system_hook if it is a secondary node' do
        expect(node.system_hook).to be_present
      end

      it 'generated system_hook has required attributes' do
        expect(node.system_hook.url).to be_present
        expect(node.system_hook.url).to eq(node.geo_events_url)
        expect(node.system_hook.token).to be_present
        expect(node.system_hook.push_events).to be_truthy
        expect(node.system_hook.tag_push_events).to be_truthy
      end
    end
  end

  describe '#uri' do
    context 'when all fields are filled' do
      it 'returns an URI object' do
        expect(new_node.uri).to be_a URI
      end

      it 'includes schema home port and relative_url' do
        expected_uri = URI.parse(dummy_url)
        expect(new_node.uri).to eq(expected_uri)
      end
    end

    context 'when required fields are not filled' do
      it 'returns an URI object' do
        expect(empty_node.uri).to be_a URI
      end
    end
  end

  describe '#url' do
    it 'returns a string' do
      expect(new_node.url).to be_a String
    end

    it 'includes schema home port and relative_url' do
      expected_url = 'https://localhost:3000/gitlab'
      expect(new_node.url).to eq(expected_url)
    end
  end

  describe '#url=' do
    subject { GeoNode.new }

    before(:each) { subject.url = dummy_url }

    it 'sets schema field based on url' do
      expect(subject.schema).to eq('https')
    end

    it 'sets host field based on url' do
      expect(subject.host).to eq('localhost')
    end

    it 'sets port field based on specified by url' do
      expect(subject.port).to eq(3000)
    end

    context 'when unspecified ports' do
      let(:dummy_http) { 'http://example.com/' }
      let(:dummy_https) { 'https://example.com/' }

      it 'sets port 80 when http and no port is specified' do
        subject.url = dummy_http
        expect(subject.port).to eq(80)
      end

      it 'sets port 443 when https and no port is specified' do
        subject.url = dummy_https
        expect(subject.port).to eq(443)
      end
    end
  end

  describe '#notify_projects_url' do
    let(:refresh_url) { 'https://localhost:3000/gitlab/api/v3/geo/refresh_projects' }

    it 'returns api url based on node uri' do
      expect(new_node.notify_projects_url).to eq(refresh_url)
    end
  end

  describe '#notify_wikis_url' do
    let(:refresh_url) { 'https://localhost:3000/gitlab/api/v3/geo/refresh_wikis' }

    it 'returns api url based on node uri' do
      expect(new_node.notify_wikis_url).to eq(refresh_url)
    end
  end

  describe '#geo_events_url' do
    let(:events_url) { 'https://localhost:3000/gitlab/api/v3/geo/receive_events' }

    it 'returns api url based on node uri' do
      expect(new_node.geo_events_url).to eq(events_url)
    end
  end

  describe '#oauth_callback_url' do
    let(:oauth_callback_url) { 'https://localhost:3000/gitlab/oauth/geo/callback' }

    it 'returns oauth callback url based on node uri' do
      expect(new_node.oauth_callback_url).to eq(oauth_callback_url)
    end

    it 'returns url that matches rails url_helpers generated one' do
      route = url_helpers.oauth_geo_callback_url(protocol: 'https:', host: 'localhost', port: 3000, script_name: '/gitlab')
      expect(new_node.oauth_callback_url).to eq(route)
    end
  end

  describe '#oauth_logout_url' do
    let(:fake_state) { URI.encode('fakestate') }
    let(:oauth_logout_url) { "https://localhost:3000/gitlab/oauth/geo/logout?state=#{fake_state}" }

    it 'returns oauth logout url based on node uri' do
      expect(new_node.oauth_logout_url(fake_state)).to eq(oauth_logout_url)
    end

    it 'returns url that matches rails url_helpers generated one' do
      route = url_helpers.oauth_geo_logout_url(protocol: 'https:', host: 'localhost', port: 3000, script_name: '/gitlab', state: fake_state)
      expect(new_node.oauth_logout_url(fake_state)).to eq(route)
    end
  end

  describe '#missing_oauth_application?' do
    context 'on a primary node' do
      it 'returns false' do
        expect(primary_node).not_to be_missing_oauth_application
      end
    end

    it 'returns false when present' do
      expect(node).not_to be_missing_oauth_application
    end

    it 'returns true when it is not present' do
      node.oauth_application.destroy!
      node.reload
      expect(node).to be_missing_oauth_application
    end
  end
end
