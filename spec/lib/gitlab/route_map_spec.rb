require 'spec_helper'

describe Gitlab::RouteMap do
  describe '#initialize' do
    context 'when the data is not YAML' do
      it 'raises an error' do
        expect { described_class.new('"') }
          .to raise_error(Gitlab::RouteMap::FormatError, /valid YAML/)
      end
    end

    context 'when the data is not a YAML array' do
      it 'raises an error' do
        expect { described_class.new(YAML.dump('foo')) }
          .to raise_error(Gitlab::RouteMap::FormatError, /an array/)
      end
    end

    context 'when an entry is not a hash' do
      it 'raises an error' do
        expect { described_class.new(YAML.dump(['foo'])) }
          .to raise_error(Gitlab::RouteMap::FormatError, /a hash/)
      end
    end

    context 'when an entry does not have a source key' do
      it 'raises an error' do
        expect { described_class.new(YAML.dump([{ 'public' => 'index.html' }])) }
          .to raise_error(Gitlab::RouteMap::FormatError, /source key/)
      end
    end

    context 'when an entry does not have a public key' do
      it 'raises an error' do
        expect { described_class.new(YAML.dump([{ 'source' => '/index\.html/' }])) }
          .to raise_error(Gitlab::RouteMap::FormatError, /public key/)
      end
    end

    context 'when an entry source is not a valid regex' do
      it 'raises an error' do
        expect { described_class.new(YAML.dump([{ 'source' => '/[/', 'public' => 'index.html' }])) }
          .to raise_error(Gitlab::RouteMap::FormatError, /regular expression/)
      end
    end

    context 'when all is good' do
      it 'returns a route map' do
        route_map = described_class.new(YAML.dump([{ 'source' => 'index.haml', 'public' => 'index.html' }, { 'source' => '/(.*)\.md/', 'public' => '\1.html' }]))

        expect(route_map.public_path_for_source_path('index.haml')).to eq('index.html')
        expect(route_map.public_path_for_source_path('foo.md')).to eq('foo.html')
      end
    end
  end

  describe '#public_path_for_source_path' do
    context 'malicious regexp' do
      include_examples 'malicious regexp'

      subject do
        map = described_class.new(<<-"MAP".strip_heredoc)
        - source: '#{malicious_regexp}'
          public: '/'
        MAP

        map.public_path_for_source_path(malicious_text)
      end
    end

    subject do
      described_class.new(<<-'MAP'.strip_heredoc)
        # Team data
        - source: 'data/team.yml'
          public: 'team/'

        # Blogposts
        - source: /source/posts/([0-9]{4})-([0-9]{2})-([0-9]{2})-(.+?)\..*/ # source/posts/2017-01-30-around-the-world-in-6-releases.html.md.erb
          public: '\1/\2/\3/\4/' # 2017/01/30/around-the-world-in-6-releases/

        # HTML files
        - source: /source/(.+?\.html).*/ # source/index.html.haml
          public: '\1' # index.html

        # Other files
        - source: /source/(.*)/ # source/images/blogimages/around-the-world-in-6-releases-cover.png
          public: '\1' # images/blogimages/around-the-world-in-6-releases-cover.png
      MAP
    end

    it 'returns the public path for a provided source path' do
      expect(subject.public_path_for_source_path('data/team.yml')).to eq('team/')

      expect(subject.public_path_for_source_path('source/posts/2017-01-30-around-the-world-in-6-releases.html.md.erb')).to eq('2017/01/30/around-the-world-in-6-releases/')

      expect(subject.public_path_for_source_path('source/index.html.haml')).to eq('index.html')

      expect(subject.public_path_for_source_path('source/images/blogimages/around-the-world-in-6-releases-cover.png')).to eq('images/blogimages/around-the-world-in-6-releases-cover.png')

      expect(subject.public_path_for_source_path('.gitlab/route-map.yml')).to be_nil
    end
  end
end
