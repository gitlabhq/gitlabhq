# frozen_string_literal: true

RSpec.shared_examples 'string of domains' do |attribute|
  it 'sets single domain' do
    setting.method("#{attribute}_raw=").call('example.com')
    expect(setting.method(attribute).call).to eq(['example.com'])
  end

  it 'sets multiple domains with spaces' do
    setting.method("#{attribute}_raw=").call('example.com *.example.com')
    expect(setting.method(attribute).call).to eq(['example.com', '*.example.com'])
  end

  it 'sets multiple domains with newlines and a space' do
    setting.method("#{attribute}_raw=").call("example.com\n *.example.com")
    expect(setting.method(attribute).call).to eq(['example.com', '*.example.com'])
  end

  it 'sets multiple domains with commas' do
    setting.method("#{attribute}_raw=").call("example.com, *.example.com")
    expect(setting.method(attribute).call).to eq(['example.com', '*.example.com'])
  end

  it 'sets multiple domains with semicolon' do
    setting.method("#{attribute}_raw=").call("example.com; *.example.com")
    expect(setting.method(attribute).call).to contain_exactly('example.com', '*.example.com')
  end

  it 'sets multiple domains with mixture of everything' do
    setting.method("#{attribute}_raw=").call("example.com; *.example.com\n test.com\sblock.com   yes.com")
    expect(setting.method(attribute).call).to contain_exactly('example.com', '*.example.com', 'test.com', 'block.com', 'yes.com')
  end

  it 'removes duplicates' do
    setting.method("#{attribute}_raw=").call("example.com; example.com; 127.0.0.1; 127.0.0.1")
    expect(setting.method(attribute).call).to contain_exactly('example.com', '127.0.0.1')
  end

  it 'does not fail with garbage values' do
    setting.method("#{attribute}_raw=").call("example;34543:garbage:fdh5654;")
    expect(setting.method(attribute).call).to contain_exactly('example', '34543:garbage:fdh5654')
  end

  it 'does not raise error with nil' do
    setting.method("#{attribute}_raw=").call(nil)
    expect(setting.method(attribute).call).to eq([])
  end
end

RSpec.shared_examples 'application settings examples' do
  context 'restricted signup domains' do
    it_behaves_like 'string of domains', :domain_whitelist
  end

  context 'blacklisted signup domains' do
    it_behaves_like 'string of domains', :domain_blacklist

    it 'sets multiple domain with file' do
      setting.domain_blacklist_file = File.open(Rails.root.join('spec/fixtures/', 'domain_blacklist.txt'))
      expect(setting.domain_blacklist).to contain_exactly('example.com', 'test.com', 'foo.bar')
    end
  end

  context 'outbound_local_requests_whitelist' do
    it_behaves_like 'string of domains', :outbound_local_requests_whitelist
  end

  context 'outbound_local_requests_whitelist_arrays' do
    it 'separates the IPs and domains' do
      setting.outbound_local_requests_whitelist = [
        '192.168.1.1', '127.0.0.0/28', 'www.example.com', 'example.com',
        '::ffff:a00:2', '1:0:0:0:0:0:0:0/124', 'subdomain.example.com'
      ]

      ip_whitelist = [
        IPAddr.new('192.168.1.1'), IPAddr.new('127.0.0.0/8'),
        IPAddr.new('::ffff:a00:2'), IPAddr.new('1:0:0:0:0:0:0:0/124')
      ]
      domain_whitelist = ['www.example.com', 'example.com', 'subdomain.example.com']

      expect(setting.outbound_local_requests_whitelist_arrays).to contain_exactly(ip_whitelist, domain_whitelist)
    end

    it 'does not raise error with nil' do
      setting.outbound_local_requests_whitelist = nil

      expect(setting.outbound_local_requests_whitelist_arrays).to contain_exactly([], [])
    end
  end

  describe 'usage ping settings' do
    context 'when the usage ping is disabled in gitlab.yml' do
      before do
        allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(false)
      end

      it 'does not allow the usage ping to be configured' do
        expect(setting.usage_ping_can_be_configured?).to be_falsey
      end

      context 'when the usage ping is disabled in the DB' do
        before do
          setting.usage_ping_enabled = false
        end

        it 'returns false for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_falsey
        end
      end

      context 'when the usage ping is enabled in the DB' do
        before do
          setting.usage_ping_enabled = true
        end

        it 'returns false for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_falsey
        end
      end
    end

    context 'when the usage ping is enabled in gitlab.yml' do
      before do
        allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
      end

      it 'allows the usage ping to be configured' do
        expect(setting.usage_ping_can_be_configured?).to be_truthy
      end

      context 'when the usage ping is disabled in the DB' do
        before do
          setting.usage_ping_enabled = false
        end

        it 'returns false for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_falsey
        end
      end

      context 'when the usage ping is enabled in the DB' do
        before do
          setting.usage_ping_enabled = true
        end

        it 'returns true for usage_ping_enabled' do
          expect(setting.usage_ping_enabled).to be_truthy
        end
      end
    end
  end

  describe '#allowed_key_types' do
    it 'includes all key types by default' do
      expect(setting.allowed_key_types).to contain_exactly(*described_class::SUPPORTED_KEY_TYPES)
    end

    it 'excludes disabled key types' do
      expect(setting.allowed_key_types).to include(:ed25519)

      setting.ed25519_key_restriction = described_class::FORBIDDEN_KEY_VALUE

      expect(setting.allowed_key_types).not_to include(:ed25519)
    end
  end

  describe '#key_restriction_for' do
    it 'returns the restriction value for recognised types' do
      setting.rsa_key_restriction = 1024

      expect(setting.key_restriction_for(:rsa)).to eq(1024)
    end

    it 'allows types to be passed as a string' do
      setting.rsa_key_restriction = 1024

      expect(setting.key_restriction_for('rsa')).to eq(1024)
    end

    it 'returns forbidden for unrecognised type' do
      expect(setting.key_restriction_for(:foo)).to eq(described_class::FORBIDDEN_KEY_VALUE)
    end
  end

  describe '#allow_signup?' do
    it 'returns true' do
      expect(setting.allow_signup?).to be_truthy
    end

    it 'returns false if signup is disabled' do
      allow(setting).to receive(:signup_enabled?).and_return(false)

      expect(setting.allow_signup?).to be_falsey
    end

    it 'returns false if password authentication is disabled for the web interface' do
      allow(setting).to receive(:password_authentication_enabled_for_web?).and_return(false)

      expect(setting.allow_signup?).to be_falsey
    end
  end

  describe '#pick_repository_storage' do
    it 'uses Array#sample to pick a random storage' do
      array = double('array', sample: 'random')
      expect(setting).to receive(:repository_storages).and_return(array)

      expect(setting.pick_repository_storage).to eq('random')
    end
  end

  describe '#user_default_internal_regex_enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(:user_default_external, :user_default_internal_regex, :result) do
      false | nil                        | false
      false | ''                         | false
      false | '^(?:(?!\.ext@).)*$\r?\n?' | false
      true  | ''                         | false
      true  | nil                        | false
      true  | '^(?:(?!\.ext@).)*$\r?\n?' | true
    end

    with_them do
      before do
        setting.user_default_external = user_default_external
        setting.user_default_internal_regex = user_default_internal_regex
      end

      subject { setting.user_default_internal_regex_enabled? }

      it { is_expected.to eq(result) }
    end
  end

  describe '#archive_builds_older_than' do
    subject { setting.archive_builds_older_than }

    context 'when the archive_builds_in_seconds is set' do
      before do
        setting.archive_builds_in_seconds = 3600
      end

      it { is_expected.to be_within(1.minute).of(1.hour.ago) }
    end

    context 'when the archive_builds_in_seconds is set' do
      before do
        setting.archive_builds_in_seconds = nil
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#commit_email_hostname' do
    context 'when the value is provided' do
      before do
        setting.commit_email_hostname = 'localhost'
      end

      it 'returns the provided value' do
        expect(setting.commit_email_hostname).to eq('localhost')
      end
    end

    context 'when the value is not provided' do
      it 'returns the default from the class' do
        expect(setting.commit_email_hostname)
          .to eq(described_class.default_commit_email_hostname)
      end
    end
  end

  it 'predicate method changes when value is updated' do
    setting.password_authentication_enabled_for_web = false

    expect(setting.password_authentication_enabled_for_web?).to be_falsey
  end
end
