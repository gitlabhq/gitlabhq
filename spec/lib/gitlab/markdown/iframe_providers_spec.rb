# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Markdown::IframeProviders, feature_category: :markdown do
  after do
    described_class.reset!
  end

  before do
    stub_application_setting(iframe_rendering_allowlist: %w[youtube figma])
  end

  def match(url)
    result = described_class.match(url)
    result && [result.url, result.provider.id]
  end

  describe '.known_providers' do
    it 'loads every provider from the config file', :aggregate_failures do
      providers = described_class.known_providers

      expect(providers).to all(be_a(described_class::Provider))
      expect(providers.map(&:id)).to eq(%w[youtube figma])
    end

    it 'caches the loaded providers' do
      providers = described_class.known_providers

      expect(described_class.known_providers).to be(providers)
    end

    context 'when the config is broken' do
      before do
        allow(described_class).to receive(:load_config!).and_return([])
      end

      it 'returns no providers' do
        expect(described_class.known_providers).to eq([])
      end

      it 'logs the error' do
        expect(Gitlab::AppLogger).to receive(:error)
          .with(message: 'Ignoring iframe provider configuration',
            Labkit::Fields::ERROR_MESSAGE => /expected a mapping of provider IDs/)

        described_class.known_providers
      end

      it 'loads the config only once' do
        expect(described_class).to receive(:load_config!).once

        described_class.known_providers
        described_class.known_providers
      end
    end

    context 'when the config is not valid YAML' do
      before do
        allow(YAML).to receive(:safe_load_file).with(described_class::PROVIDERS_PATH)
          .and_raise(Psych::SyntaxError.new('file', 1, 2, 3, 'bad syntax', nil))
      end

      it 'returns no providers' do
        expect(described_class.known_providers).to eq([])
      end

      it 'logs the error' do
        expect(Gitlab::AppLogger).to receive(:error)
          .with(message: 'Ignoring iframe provider configuration',
            Labkit::Fields::ERROR_MESSAGE => /iframe_providers\.yml: .*bad syntax/)

        described_class.known_providers
      end
    end
  end

  describe '.enabled_providers' do
    it 'returns only providers in the allowlist, in config order' do
      stub_application_setting(iframe_rendering_allowlist: %w[figma])

      expect(described_class.enabled_providers.map(&:id)).to eq(%w[figma])
    end

    it 'ignores unknown allowlist entries' do
      stub_application_setting(iframe_rendering_allowlist: %w[www.youtube.com youtube])

      expect(described_class.enabled_providers.map(&:id)).to eq(%w[youtube])
    end
  end

  describe '.match' do
    context 'with YouTube URLs' do
      it 'transforms a watch URL to an embed URL' do
        expect(match('https://www.youtube.com/watch?v=dQw4w9WgXcQ'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'discards extra query parameters' do
        expect(match('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'does not match a watch URL without the v parameter', :aggregate_failures do
        expect(match('https://www.youtube.com/watch')).to be_nil
        expect(match('https://www.youtube.com/watch?t=120')).to be_nil
      end

      it 'does not match a watch URL with an empty v parameter', :aggregate_failures do
        expect(match('https://www.youtube.com/watch?v=')).to be_nil
        expect(match('https://www.youtube.com/watch?v')).to be_nil
      end

      it 'transforms a youtu.be URL to an embed URL' do
        expect(match('https://youtu.be/dQw4w9WgXcQ?t=120'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'does not match a youtu.be URL without a video ID', :aggregate_failures do
        expect(match('https://youtu.be')).to be_nil
        expect(match('https://youtu.be/')).to be_nil
        expect(match('https://youtu.be//dQw4w9WgXcQ')).to be_nil
      end

      it 'accepts an embed URL, discarding its query' do
        expect(match('https://www.youtube.com/embed/dQw4w9WgXcQ?start=30'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'does not match other paths on the YouTube host', :aggregate_failures do
        expect(match('https://www.youtube.com/account')).to be_nil
        expect(match('https://www.youtube.com/')).to be_nil
      end

      it 'does not match a path differing in case' do
        expect(match('https://www.youtube.com/EMBED/dQw4w9WgXcQ')).to be_nil
      end

      it 'matches the host case-insensitively' do
        expect(match('https://WWW.YouTube.com/embed/dQw4w9WgXcQ'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'matches the scheme case-insensitively' do
        expect(match('HTTPS://www.youtube.com/embed/dQw4w9WgXcQ'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'discards credentials from the embed URL' do
        expect(match('https://user:password@www.youtube.com/embed/dQw4w9WgXcQ'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end

      it 'discards a port from the embed URL' do
        expect(match('https://www.youtube.com:8443/embed/dQw4w9WgXcQ'))
          .to eq(['https://www.youtube.com/embed/dQw4w9WgXcQ', 'youtube'])
      end
    end

    context 'with Figma URLs' do
      %w[proto design board file slides].each do |type|
        it "transforms a #{type} URL to an embed URL" do
          expect(match("https://www.figma.com/#{type}/abc123"))
            .to eq(["https://embed.figma.com/#{type}/abc123?embed-host=gitlab", 'figma'])
        end
      end

      it 'discards the name slug and query parameters' do
        url = 'https://www.figma.com/proto/FJDXeV6NVQGMgcJWCwwPpx/Wiki-Vision?page-id=125%3A36092&node-id=126-75639'

        expect(match(url)).to eq(['https://embed.figma.com/proto/FJDXeV6NVQGMgcJWCwwPpx?embed-host=gitlab', 'figma'])
      end

      it 'accepts an embed URL' do
        expect(match('https://embed.figma.com/design/abc123?embed-host=gitlab'))
          .to eq(['https://embed.figma.com/design/abc123?embed-host=gitlab', 'figma'])
      end

      it 'does not match an unrecognized type', :aggregate_failures do
        expect(match('https://www.figma.com/kalamaja/abc123')).to be_nil
        expect(match('https://embed.figma.com/kalamaja/abc123')).to be_nil
      end

      it 'does not match a URL missing the ID segment' do
        expect(match('https://www.figma.com/design')).to be_nil
      end
    end

    context 'with special characters in captures' do
      it 'percent-encodes reserved characters captured from a query parameter', :aggregate_failures do
        expect(match('https://www.youtube.com/watch?v=abc%26autoplay%3D1'))
          .to eq(['https://www.youtube.com/embed/abc%26autoplay%3D1', 'youtube'])
        expect(match('https://www.youtube.com/watch?v=abc%23t%3D0'))
          .to eq(['https://www.youtube.com/embed/abc%23t%3D0', 'youtube'])
      end

      it 'percent-encodes reserved characters captured from a path segment', :aggregate_failures do
        expect(match('https://www.figma.com/design/abc%3Fembed-host%3Dattacker/title'))
          .to eq(['https://embed.figma.com/design/abc%3Fembed-host%3Dattacker?embed-host=gitlab', 'figma'])
        expect(match('https://youtu.be/abc%23autoplay=1'))
          .to eq(['https://www.youtube.com/embed/abc%23autoplay%3D1', 'youtube'])
      end

      it 'round-trips percent-encoded unreserved characters' do
        expect(match('https://youtu.be/abc%2Ddef')).to eq(['https://www.youtube.com/embed/abc-def', 'youtube'])
      end
    end

    context 'with URLs that never match' do
      where(:url) do
        [
          'https://example.com/page',
          'https://www.youtube.com.evil.example/embed/abc',
          'http://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'not a url at all',
          'http:// .example',
          '',
          nil
        ]
      end

      with_them do
        it { expect(match(url)).to be_nil }
      end
    end

    context 'when the matching provider is not enabled' do
      before do
        stub_application_setting(iframe_rendering_allowlist: %w[figma])
      end

      it 'returns nil' do
        expect(match('https://www.youtube.com/embed/dQw4w9WgXcQ')).to be_nil
      end
    end

    context 'with requires that a rule cannot satisfy' do
      before do
        allow(described_class).to receive(:load_config!).and_return(
          'example' => {
            'name' => 'Example',
            'matches' => [
              { 'host' => 'a.example', 'path' => '/{kind}/{id}' },
              { 'host' => 'b.example', 'path' => '/{kind}/{id}' }
            ],
            'requires' => { 'kind' => %w[one] },
            'src' => 'https://embed.example/{id}',
            'sandbox' => []
          })
        stub_application_setting(iframe_rendering_allowlist: %w[example])
      end

      it 'matches when the requirement is met' do
        expect(match('https://b.example/one/x')).to eq(['https://embed.example/x', 'example'])
      end

      it 'does not match when the requirement is not met' do
        expect(match('https://a.example/two/x')).to be_nil
      end
    end
  end
end
