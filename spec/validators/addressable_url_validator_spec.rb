# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AddressableUrlValidator do
  let!(:badge) { build(:badge, link_url: 'http://www.example.com') }

  let(:validator) { described_class.new(validator_options.reverse_merge(attributes: [:link_url])) }
  let(:validator_options) { {} }

  subject { validator.validate(badge) }

  include_examples 'url validator examples', described_class::DEFAULT_OPTIONS[:schemes]

  describe 'validations' do
    include_context 'invalid urls'

    let(:validator) { described_class.new(attributes: [:link_url]) }

    it 'returns error when url is nil' do
      expect(validator.validate_each(badge, :link_url, nil)).to be_falsey
      expect(badge.errors.added?(:link_url, validator.options.fetch(:message))).to be true
    end

    it 'returns error when url is empty' do
      expect(validator.validate_each(badge, :link_url, '')).to be_falsey
      expect(badge.errors.added?(:link_url, validator.options.fetch(:message))).to be true
    end

    it 'does not allow urls with CR or LF characters' do
      aggregate_failures do
        urls_with_CRLF.each do |url|
          validator.validate_each(badge, :link_url, url)

          expect(badge.errors.added?(:link_url, 'is blocked: URI is invalid')).to be true
        end
      end
    end

    it 'provides all arguments to UrlBlock validate' do
      expect(Gitlab::UrlBlocker)
          .to receive(:validate!)
                  .with(badge.link_url, described_class::BLOCKER_VALIDATE_OPTIONS)
                  .and_return(true)

      subject

      expect(badge.errors).to be_empty
    end
  end

  context 'by default' do
    let(:validator) { described_class.new(attributes: [:link_url]) }

    it 'does not block urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors).to be_empty
    end

    it 'does not block urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors).to be_empty
    end

    it 'does block nil urls' do
      badge.link_url = nil

      subject

      expect(badge.errors).to be_present
    end

    it 'does block blank urls' do
      badge.link_url = '\n\r \n'

      subject

      expect(badge.errors).to be_present
    end

    it 'strips urls' do
      badge.link_url = "\n\r\n\nhttps://127.0.0.1\r\n\r\n\n\n\n"

      # It's unusual for a validator to modify its arguments. Some extensions,
      # such as attr_encrypted, freeze the string to signal that modifications
      # will not be persisted, so freeze this string to ensure the scheme is
      # compatible with them.
      badge.link_url.freeze

      subject

      expect(badge.errors).to be_empty
      expect(badge.link_url).to eq('https://127.0.0.1')
    end

    it 'allows urls that cannot be resolved' do
      stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')
      badge.link_url = 'http://foobar.x'

      subject

      expect(badge.errors).to be_empty
    end
  end

  context 'when message is set' do
    let(:message) { 'is blocked: test message' }
    let(:validator) { described_class.new(attributes: [:link_url], allow_nil: false, message: message) }

    it 'does block nil url with provided error message' do
      expect(validator.validate_each(badge, :link_url, nil)).to be_falsey
      expect(badge.errors.added?(:link_url, message)).to be true
    end
  end

  context 'when blocked_message is set' do
    let(:message) { 'is not allowed due to: %{exception_message}' }
    let(:validator_options) { { blocked_message: message } }

    it 'blocks url with provided error message' do
      badge.link_url = 'javascript:alert(window.opener.document.location)'

      subject

      expect(badge.errors.added?(:link_url, 'is not allowed due to: Only allowed schemes are http, https')).to be true
    end
  end

  context 'when allow_nil is set to true' do
    let(:validator) { described_class.new(attributes: [:link_url], allow_nil: true) }

    it 'does not block nil urls' do
      badge.link_url = nil

      subject

      expect(badge.errors).to be_empty
    end
  end

  context 'when allow_blank is set to true' do
    let(:validator) { described_class.new(attributes: [:link_url], allow_blank: true) }

    it 'does not block blank urls' do
      badge.link_url = "\n\r \n"

      subject

      expect(badge.errors).to be_empty
    end
  end

  context 'when allow_localhost is set to false' do
    let(:validator) { described_class.new(attributes: [:link_url], allow_localhost: false) }

    it 'blocks urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors).to be_present
    end

    context 'when allow_setting_local_requests is set to true' do
      it 'does not block urls pointing to localhost' do
        expect(described_class)
          .to receive(:allow_setting_local_requests?)
            .and_return(true)

        badge.link_url = 'https://127.0.0.1'

        subject

        expect(badge.errors).to be_empty
      end
    end
  end

  context 'when allow_local_network is set to false' do
    let(:validator) { described_class.new(attributes: [:link_url], allow_local_network: false) }

    it 'blocks urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors).to be_present
    end

    context 'when allow_setting_local_requests is set to true' do
      it 'does not block urls pointing to local network' do
        expect(described_class)
          .to receive(:allow_setting_local_requests?)
            .and_return(true)

        badge.link_url = 'https://192.168.1.1'

        subject

        expect(badge.errors).to be_empty
      end
    end
  end

  context 'when ports is' do
    let(:validator) { described_class.new(attributes: [:link_url], ports: ports) }

    context 'empty' do
      let(:ports) { [] }

      it 'does not block any port' do
        subject

        expect(badge.errors).to be_empty
      end
    end

    context 'set' do
      let(:ports) { [443] }

      it 'blocks urls with a different port' do
        subject

        expect(badge.errors).to be_present
      end
    end
  end

  context 'when enforce_user is' do
    let(:url) { 'http://$user@example.com'}
    let(:validator) { described_class.new(attributes: [:link_url], enforce_user: enforce_user) }

    context 'true' do
      let(:enforce_user) { true }

      it 'checks user format' do
        badge.link_url = url

        subject

        expect(badge.errors).to be_present
      end
    end

    context 'false (default)' do
      let(:enforce_user) { false }

      it 'does not check user format' do
        badge.link_url = url

        subject

        expect(badge.errors).to be_empty
      end
    end
  end

  context 'when ascii_only is' do
    let(:url) { 'https://𝕘itⅼαƄ.com/foo/foo.bar'}
    let(:validator) { described_class.new(attributes: [:link_url], ascii_only: ascii_only) }

    context 'true' do
      let(:ascii_only) { true }

      it 'prevents unicode characters' do
        badge.link_url = url

        subject

        expect(badge.errors).to be_present
      end
    end

    context 'false (default)' do
      let(:ascii_only) { false }

      it 'does not prevent unicode characters' do
        badge.link_url = url

        subject

        expect(badge.errors).to be_empty
      end
    end
  end

  context 'when enforce_sanitization is' do
    let(:validator) { described_class.new(attributes: [:link_url], enforce_sanitization: enforce_sanitization) }
    let(:unsafe_url) { "https://replaceme.com/'><script>alert(document.cookie)</script>" }
    let(:safe_url) { 'https://replaceme.com/path/to/somewhere' }

    let(:unsafe_internal_url) do
      Gitlab.config.gitlab.protocol + '://' + Gitlab.config.gitlab.host +
        "/'><script>alert(document.cookie)</script>"
    end

    context 'true' do
      let(:enforce_sanitization) { true }

      it 'prevents unsafe urls' do
        badge.link_url = unsafe_url

        subject

        expect(badge.errors).to be_present
      end

      it 'prevents unsafe internal urls' do
        badge.link_url = unsafe_internal_url

        subject

        expect(badge.errors).to be_present
      end

      it 'allows safe urls' do
        badge.link_url = safe_url

        subject

        expect(badge.errors).to be_empty
      end
    end

    context 'false' do
      let(:enforce_sanitization) { false }

      it 'allows unsafe urls' do
        badge.link_url = unsafe_url

        subject

        expect(badge.errors).to be_empty
      end
    end
  end

  context 'when dns_rebind_protection is' do
    let(:not_resolvable_url) { 'http://foobar.x' }
    let(:validator) { described_class.new(attributes: [:link_url], dns_rebind_protection: dns_value) }

    before do
      stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')
      badge.link_url = not_resolvable_url

      subject
    end

    context 'true' do
      let(:dns_value) { true }

      it 'raises error' do
        expect(badge.errors).to be_present
      end
    end

    context 'false' do
      let(:dns_value) { false }

      it 'allows urls that cannot be resolved' do
        expect(badge.errors).to be_empty
      end
    end
  end
end
