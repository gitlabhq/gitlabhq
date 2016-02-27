require 'spec_helper'

describe GeoNode, type: :model do

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

    it 'defines a default primary flag' do
      expect(subject.primary).to eq(false)
    end
  end

  describe '#uri' do
    context 'when all fields are filled' do
      subject { GeoNode.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }

      it 'returns an URI object' do
        expect(subject.uri).to be_a URI
      end

      it 'includes schema home port and relative_url' do
        expected_uri = URI.parse('https://localhost:3000/gitlab')
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

  describe '#notify_url' do
    subject { GeoNode.new(schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }

    it 'returns api url based on node uri' do
      expect(subject.notify_url).to eq('https://localhost:3000/gitlab/api/geo/refresh_projects')
    end
  end

end
