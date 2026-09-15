# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Markdown::IframeProviders::Provider, feature_category: :markdown do
  let(:valid_entry) do
    {
      'name' => 'Example',
      'matches' => [
        { 'host' => 'www.example.com', 'path' => '/{kind}/{id}' },
        { 'host' => 'example.com', 'path' => '/view', 'params' => %w[kind id] }
      ],
      'requires' => { 'kind' => %w[video audio] },
      'src' => 'https://embed.example.com/{kind}/{id}?host=gitlab',
      'sandbox' => %w[allow-scripts allow-popups],
      'require_activation' => false
    }
  end

  def from_config(id = 'example', **overrides)
    described_class.from_config(id, valid_entry.merge(overrides.stringify_keys))
  end

  def expect_config_error(message, id = 'example', **overrides)
    expect { from_config(id, **overrides) }
      .to raise_error(Gitlab::Markdown::IframeProviders::ConfigError, /provider '#{id}': #{message}/)
  end

  describe '.from_config' do
    it 'builds a provider from a valid entry' do
      provider = from_config

      expect(provider).to have_attributes(
        id: 'example',
        name: 'Example',
        requires: { 'kind' => %w[video audio] },
        src: 'https://embed.example.com/{kind}/{id}?host=gitlab',
        src_origin: 'https://embed.example.com',
        sandbox: %w[allow-scripts allow-popups],
        require_activation: false
      )
      expect(provider.matches).to all(be_a(Gitlab::Markdown::IframeProviders::MatchRule))
      expect(provider.matches.map(&:host)).to eq(%w[www.example.com example.com])
    end

    it 'defaults require_activation to true' do
      entry = valid_entry.except('require_activation')

      expect(described_class.from_config('example', entry).require_activation).to be(true)
    end

    it 'accepts an empty sandbox' do
      expect(from_config(sandbox: []).sandbox).to eq([])
    end

    it 'accepts an entry without requires' do
      entry = valid_entry.except('requires')

      expect(described_class.from_config('example', entry).requires).to eq({})
    end

    it 'rejects an invalid ID' do
      expect_config_error('ID must match', 'Bad-ID')
      expect_config_error('ID must match', '1st')
    end

    it 'rejects a non-mapping entry' do
      expect { described_class.from_config('example', []) }
        .to raise_error(Gitlab::Markdown::IframeProviders::ConfigError, /must be a mapping/)
    end

    it 'rejects unknown keys' do
      expect_config_error('unknown keys: sandbox_flags, colour', sandbox_flags: [], colour: 'red')
    end

    it 'rejects a missing or blank name' do
      expect_config_error("missing 'name'", name: nil)
      expect_config_error("missing 'name'", name: '')
      expect_config_error("missing 'name'", name: 1)
    end

    it 'rejects missing or empty matches' do
      expect_config_error("'matches' must be a non-empty list", matches: nil)
      expect_config_error("'matches' must be a non-empty list", matches: [])
      expect_config_error("'matches' must be a non-empty list", matches: { 'host' => 'example.com', 'path' => '/' })
    end

    describe 'match rules' do
      it 'rejects a non-mapping rule' do
        expect_config_error('match rule must be a mapping', matches: ['example.com'])
      end

      it 'rejects a missing host' do
        expect_config_error("match rule missing 'host'", matches: [{ 'path' => '/{kind}/{id}' }])
      end

      it 'rejects a missing path' do
        expect_config_error("match rule missing 'path'", matches: [{ 'host' => 'example.com' }])
      end

      it 'rejects a path not starting with /' do
        expect_config_error("match rule 'path' must start with /",
          matches: [{ 'host' => 'example.com', 'path' => '{kind}/{id}' }])
      end

      it 'rejects params that are not a list of strings' do
        expect_config_error("match rule 'params' must be a list of strings",
          matches: [{ 'host' => 'example.com', 'path' => '/{kind}/{id}', 'params' => 'v' }])
      end
    end

    it 'rejects malformed requires' do
      expect_config_error("'requires' must be a mapping", requires: %w[kind])
      expect_config_error("'requires' must be a mapping", requires: { 'kind' => 'video' })
      expect_config_error("'requires' must be a mapping", requires: { 'kind' => [1] })
    end

    it 'rejects requires on a capture some rule does not provide' do
      expect_config_error('captures colour are not provided by the match rule for www.example.com',
        requires: { 'colour' => %w[red] })
    end

    describe 'src' do
      it 'rejects a missing src' do
        expect_config_error("missing 'src'", src: nil)
      end

      it 'rejects a non-https src' do
        expect_config_error("'src' must be an https URL with a host", src: 'http://embed.example.com/{kind}/{id}')
        expect_config_error("'src' must be an https URL with a host", src: '/{kind}/{id}')
      end

      it 'rejects an unparseable src' do
        expect_config_error("'src' is not a valid URL", src: 'https://{kind}.example.com/{id}')
      end

      it 'rejects placeholders not captured by every match rule' do
        expect_config_error('captures token are not provided by the match rule for www.example.com',
          src: 'https://embed.example.com/{kind}/{id}?token={token}')
      end
    end

    describe 'sandbox' do
      it 'rejects a missing sandbox' do
        expect_config_error("'sandbox' must be a list of flags", sandbox: nil)
      end

      it 'rejects a string sandbox' do
        expect_config_error("'sandbox' must be a list of flags", sandbox: 'allow-scripts')
      end

      it 'rejects unpermitted flags' do
        expect_config_error('unpermitted sandbox flags: allow-top-navigation allow-forms',
          sandbox: %w[allow-scripts allow-top-navigation allow-forms])
      end

      context 'with allow-same-origin' do
        before do
          stub_config(gitlab: { host: 'gitlab.example.com' }, pages: { host: 'pages.example.com' })
        end

        it 'accepts a src hosted elsewhere' do
          expect(from_config(sandbox: %w[allow-same-origin]).sandbox).to eq(%w[allow-same-origin])
        end

        it 'rejects a src hosted on the instance' do
          expect_config_error("'src' must not be hosted by this GitLab instance when 'allow-same-origin' is set",
            src: 'https://gitlab.example.com/{kind}/{id}', sandbox: %w[allow-same-origin])
        end

        it 'rejects a src hosted on the instance under a different case' do
          expect_config_error("'src' must not be hosted by this GitLab instance when 'allow-same-origin' is set",
            src: 'https://GitLab.Example.COM/{kind}/{id}', sandbox: %w[allow-same-origin])
          expect_config_error("'src' must not be hosted by this GitLab instance when 'allow-same-origin' is set",
            src: 'https://Group.Pages.Example.COM/{kind}/{id}', sandbox: %w[allow-same-origin])
        end

        it 'rejects a src hosted on GitLab Pages' do
          expect_config_error("'src' must not be hosted by this GitLab instance when 'allow-same-origin' is set",
            src: 'https://pages.example.com/{kind}/{id}', sandbox: %w[allow-same-origin])
          expect_config_error("'src' must not be hosted by this GitLab instance when 'allow-same-origin' is set",
            src: 'https://group.pages.example.com/{kind}/{id}', sandbox: %w[allow-same-origin])
        end

        it 'accepts a src hosted on the instance without allow-same-origin' do
          provider = from_config(src: 'https://gitlab.example.com/{kind}/{id}', sandbox: %w[allow-scripts])

          expect(provider.src_origin).to eq('https://gitlab.example.com')
        end
      end
    end

    it 'rejects a non-boolean require_activation' do
      expect_config_error("'require_activation' must be a boolean", require_activation: 'yes')
      expect_config_error("'require_activation' must be a boolean", require_activation: nil)
    end
  end

  describe '#match' do
    let(:provider) { from_config }

    def match(url)
      provider.match(Addressable::URI.parse(url))
    end

    it 'expands the src with path captures' do
      expect(match('https://www.example.com/video/abc/slug')).to eq('https://embed.example.com/video/abc?host=gitlab')
    end

    it 'matches a host under a different case' do
      expect(match('https://WWW.Example.COM/video/abc')).to eq('https://embed.example.com/video/abc?host=gitlab')
    end

    it 'matches a rule configured with a host under a different case' do
      provider = from_config(matches: [{ 'host' => 'WWW.Example.COM', 'path' => '/{kind}/{id}' }])

      expect(provider.match(Addressable::URI.parse('https://www.example.com/video/abc')))
        .to eq('https://embed.example.com/video/abc?host=gitlab')
    end

    it 'expands the src with query captures' do
      expect(match('https://example.com/view?id=abc&kind=audio&x=1'))
        .to eq('https://embed.example.com/audio/abc?host=gitlab')
    end

    it 'returns nil when no rule matches' do
      expect(match('https://example.com/video/abc')).to be_nil
      expect(match('https://www.example.com/video')).to be_nil
      expect(match('https://example.com/view?kind=video')).to be_nil
    end

    it 'returns nil when a capture segment is empty' do
      expect(match('https://www.example.com/video//slug')).to be_nil
      expect(match('https://www.example.com//abc')).to be_nil
    end

    it 'returns nil when a requirement is not met' do
      expect(match('https://www.example.com/image/abc')).to be_nil
      expect(match('https://example.com/view?id=abc&kind=image')).to be_nil
    end
  end
end
