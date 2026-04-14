# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Markdown::IframeUrlTransforms, feature_category: :markdown do
  after do
    described_class.reset!
  end

  describe '.transform' do
    context 'with YouTube watch URLs' do
      it 'transforms a standard watch URL to an embed URL' do
        expect(described_class.transform('https://www.youtube.com/watch?v=dQw4w9WgXcQ'))
          .to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
      end

      it 'handles video IDs with hyphens and underscores' do
        expect(described_class.transform('https://www.youtube.com/watch?v=A-b_1Cd_2EF'))
          .to eq('https://www.youtube.com/embed/A-b_1Cd_2EF')
      end

      it 'discards extra query parameters' do
        expect(described_class.transform('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120'))
          .to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
      end

      it 'returns the URL unchanged when there is no query string' do
        url = 'https://www.youtube.com/watch'
        expect(described_class.transform(url)).to eq(url)
      end

      it 'returns the URL unchanged when the required param is missing' do
        url = 'https://www.youtube.com/watch?t=120'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with YouTube short URLs' do
      it 'transforms a youtu.be URL to an embed URL' do
        expect(described_class.transform('https://youtu.be/dQw4w9WgXcQ'))
          .to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
      end

      it 'discards extra path or query content' do
        expect(described_class.transform('https://youtu.be/dQw4w9WgXcQ?t=120'))
          .to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
      end

      it 'returns the URL unchanged when there is no path' do
        url = 'https://youtu.be'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with YouTube embed URLs' do
      it 'does not transform an already-embeddable URL' do
        url = 'https://www.youtube.com/embed/dQw4w9WgXcQ'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with Figma URLs' do
      it 'transforms a design URL to an embed URL' do
        expect(described_class.transform('https://www.figma.com/design/abc123'))
          .to eq('https://embed.figma.com/design/abc123?embed-host=gitlab')
      end

      it 'transforms a proto URL to an embed URL' do
        expect(described_class.transform('https://www.figma.com/proto/FJDXeV6NVQGMgcJWCwwPpx'))
          .to eq('https://embed.figma.com/proto/FJDXeV6NVQGMgcJWCwwPpx?embed-host=gitlab')
      end

      it 'transforms a board URL to an embed URL' do
        expect(described_class.transform('https://www.figma.com/board/xyz789'))
          .to eq('https://embed.figma.com/board/xyz789?embed-host=gitlab')
      end

      it 'transforms a file URL to an embed URL' do
        expect(described_class.transform('https://www.figma.com/file/abc123'))
          .to eq('https://embed.figma.com/file/abc123?embed-host=gitlab')
      end

      it 'discards the name slug and query parameters' do
        url = 'https://www.figma.com/proto/FJDXeV6NVQGMgcJWCwwPpx/Wiki-Vision?page-id=125%3A36092&node-id=126-75639'
        expect(described_class.transform(url))
          .to eq('https://embed.figma.com/proto/FJDXeV6NVQGMgcJWCwwPpx?embed-host=gitlab')
      end

      it 'transforms a slides URL to an embed URL' do
        expect(described_class.transform('https://www.figma.com/slides/abc123'))
          .to eq('https://embed.figma.com/slides/abc123?embed-host=gitlab')
      end

      it 'does not transform a Figma URL with an unrecognized type' do
        url = 'https://www.figma.com/kalamaja/abc123'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with Figma embed URLs' do
      it 'does not transform an already-embeddable URL' do
        url = 'https://embed.figma.com/design/abc123?embed-host=gitlab'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with percent-encoded special characters in query parameters' do
      it 'encodes injected ampersand in YouTube video ID' do
        expect(described_class.transform('https://www.youtube.com/watch?v=abc%26autoplay%3D1'))
          .to eq('https://www.youtube.com/embed/abc%26autoplay%3D1')
      end

      it 'encodes injected hash in YouTube video ID' do
        expect(described_class.transform('https://www.youtube.com/watch?v=abc%23t%3D0'))
          .to eq('https://www.youtube.com/embed/abc%23t%3D0')
      end
    end

    context 'with percent-encoded special characters in path segments' do
      it 'encodes injected question mark in Figma file ID' do
        expect(described_class.transform('https://www.figma.com/design/abc%3Fembed-host%3Dattacker/title'))
          .to eq('https://embed.figma.com/design/abc%3Fembed-host%3Dattacker?embed-host=gitlab')
      end

      it 'encodes injected hash in youtu.be video ID' do
        expect(described_class.transform('https://youtu.be/abc%23autoplay=1'))
          .to eq('https://www.youtube.com/embed/abc%23autoplay%3D1')
      end

      it 'round-trips path segments containing percent-encoded unreserved characters' do
        expect(described_class.transform('https://youtu.be/abc%2Ddef'))
          .to eq('https://www.youtube.com/embed/abc-def')
      end
    end

    context 'with non-matching URLs' do
      it 'returns the original URL unchanged' do
        url = 'https://example.com/page'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with non-HTTPS URLs' do
      it 'returns an HTTP URL unchanged' do
        url = 'http://www.youtube.com/watch?v=dQw4w9WgXcQ'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with invalid URLs' do
      it 'returns the original string unchanged' do
        url = 'not a url at all'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with unparseable URLs' do
      it 'returns the original string unchanged' do
        url = 'http:// .example'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'with blank input' do
      it 'returns blank for nil' do
        expect(described_class.transform(nil)).to be_nil
      end

      it 'returns blank for empty string' do
        expect(described_class.transform('')).to eq('')
      end
    end

    it 'applies only the first matching rule' do
      url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
      result = described_class.transform(url)

      expect(result).to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
    end

    context 'with a nil path on a matching host' do
      before do
        allow(described_class).to receive(:load_config!).and_return([
          { 'from' => { 'host' => 'example.com', 'path' => '/{id}' }, 'to' => 'https://example.com/embed/{id}' }
        ])
      end

      it 'returns the URL unchanged when the URI has no path' do
        url = 'https://example.com'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'when the path has fewer segments than the rule requires' do
      before do
        allow(described_class).to receive(:load_config!).and_return([
          { 'from' => { 'host' => 'example.com', 'path' => '/{a}/{b}/{c}' },
            'to' => 'https://example.com/{a}/{b}/{c}' }
        ])
      end

      it 'returns the URL unchanged' do
        url = 'https://example.com/one/two'
        expect(described_class.transform(url)).to eq(url)
      end
    end

    context 'when the template contains a placeholder with no matching capture' do
      before do
        allow(described_class).to receive(:load_config!).and_return([
          { 'from' => { 'host' => 'example.com', 'path' => '/{id}' },
            'to' => 'https://example.com/embed/{id}?token={missing}' }
        ])
      end

      it 'leaves the unmatched placeholder unchanged in the output' do
        expect(described_class.transform('https://example.com/abc'))
          .to eq('https://example.com/embed/abc?token={missing}')
      end
    end
  end

  describe '.rules' do
    it 'loads rules from the YAML config' do
      rules = described_class.rules

      expect(rules).to be_an(Array)
      expect(rules).not_to be_empty
      expect(rules).to all(be_a(described_class::Rule))
    end

    it 'caches the loaded rules' do
      first_call = described_class.rules
      second_call = described_class.rules

      expect(first_call).to be(second_call)
    end

    it 'raises when a path does not start with /' do
      allow(described_class).to receive(:load_config!).and_return([
        { 'from' => { 'host' => 'example.com', 'path' => '{x}/{y}' }, 'to' => 'https://example.com/{x}' }
      ])

      expect { described_class.rules }
        .to raise_error(RuntimeError, %r{must start with /})
    end

    it "raises when 'from' is not a Hash" do
      allow(described_class).to receive(:load_config!).and_return([
        { 'from' => 'bad', 'to' => 'https://example.com/' }
      ])

      expect { described_class.rules }
        .to raise_error(RuntimeError, /rule missing 'from'/)
    end

    it "raises when 'from.host' is missing" do
      allow(described_class).to receive(:load_config!).and_return([
        { 'from' => { 'path' => '/{id}' }, 'to' => 'https://example.com/{id}' }
      ])

      expect { described_class.rules }
        .to raise_error(RuntimeError, /rule missing 'from\.host'/)
    end

    it "raises when 'from.path' is missing" do
      allow(described_class).to receive(:load_config!).and_return([
        { 'from' => { 'host' => 'example.com' }, 'to' => 'https://example.com/' }
      ])

      expect { described_class.rules }
        .to raise_error(RuntimeError, /rule missing 'from\.path'/)
    end

    it "raises when 'to' is missing" do
      allow(described_class).to receive(:load_config!).and_return([
        { 'from' => { 'host' => 'example.com', 'path' => '/{id}' } }
      ])

      expect { described_class.rules }
        .to raise_error(RuntimeError, /rule missing 'to'/)
    end
  end
end
