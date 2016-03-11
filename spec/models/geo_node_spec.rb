require 'spec_helper'

describe GeoNode, type: :model do
  let(:dummy_url) { 'https://localhost:3000/gitlab' }

  context 'associations' do
    it { is_expected.to belong_to(:geo_node_key).dependent(:destroy) }
    it { is_expected.to belong_to(:oauth_application).dependent(:destroy) }
  end

  context 'default values' do
    let(:gitlab_host) { 'gitlabhost' }
    before(:each) { allow(Gitlab.config.gitlab).to receive(:host) { gitlab_host } }

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
    subject { GeoNode.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }

    context 'on initialize' do
      before(:each) do
        subject.geo_node_key_attributes = geo_node_key_attributes
      end

      it 'initializes a corresponding key' do
        expect(subject.geo_node_key).to be_present
      end

      it 'initializes a corresponding oauth application' do
        expect(subject.oauth_application).to be_present
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'on create' do

      before(:each) do
        subject.geo_node_key_attributes = geo_node_key_attributes
        subject.save!
      end

      it 'saves a corresponding key' do
        expect(subject.geo_node_key).to be_persisted
      end

      it 'saves a corresponding oauth application' do
        expect(subject.oauth_application).to be_persisted
      end
    end
  end

  describe '#uri' do
    context 'when all fields are filled' do
      subject { GeoNode.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }

      it 'returns an URI object' do
        expect(subject.uri).to be_a URI
      end

      it 'includes schema home port and relative_url' do
        expected_uri = URI.parse(dummy_url)
        expect(subject.uri).to eq(expected_uri)
      end
    end

    context 'when required fields are not filled' do
      subject { GeoNode.new(schema: nil, host: nil, port: nil, relative_url_root: nil) }

      it 'returns an URI object' do
        expect(subject.uri).to be_a URI
      end
    end
  end

  describe '#url' do
    subject { GeoNode.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }

    it 'returns a string' do
      expect(subject.url).to be_a String
    end

    it 'includes schema home port and relative_url' do
      expected_url = 'https://localhost:3000/gitlab'
      expect(subject.url).to eq(expected_url)
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

  describe '#notify_url' do
    subject { GeoNode.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }
    let(:refresh_url) { 'https://localhost:3000/gitlab/api/v3/geo/refresh_projects' }

    it 'returns api url based on node uri' do
      expect(subject.notify_url).to eq(refresh_url)
    end
  end
end
