# frozen_string_literal: true

RSpec.shared_examples 'string of domains' do |mapped_name, attribute|
  it 'sets single domain' do
    setting.method("#{mapped_name}_raw=").call('example.com')
    expect(setting.method(attribute).call).to eq(['example.com'])
  end

  it 'sets multiple domains with spaces' do
    setting.method("#{mapped_name}_raw=").call('example.com *.example.com')
    expect(setting.method(attribute).call).to eq(['example.com', '*.example.com'])
  end

  it 'sets multiple domains with newlines and a space' do
    setting.method("#{mapped_name}_raw=").call("example.com\n *.example.com")
    expect(setting.method(attribute).call).to eq(['example.com', '*.example.com'])
  end

  it 'sets multiple domains with commas' do
    setting.method("#{mapped_name}_raw=").call("example.com, *.example.com")
    expect(setting.method(attribute).call).to eq(['example.com', '*.example.com'])
  end

  it 'sets multiple domains with semicolon' do
    setting.method("#{mapped_name}_raw=").call("example.com; *.example.com")
    expect(setting.method(attribute).call).to contain_exactly('example.com', '*.example.com')
  end

  it 'sets multiple domains with mixture of everything' do
    setting.method("#{mapped_name}_raw=").call("example.com; *.example.com\n test.com\sblock.com   yes.com")
    expect(setting.method(attribute).call).to contain_exactly('example.com', '*.example.com', 'test.com', 'block.com', 'yes.com')
  end

  it 'removes duplicates' do
    setting.method("#{mapped_name}_raw=").call("example.com; example.com; 127.0.0.1; 127.0.0.1")
    expect(setting.method(attribute).call).to contain_exactly('example.com', '127.0.0.1')
  end

  it 'does not fail with garbage values' do
    setting.method("#{mapped_name}_raw=").call("example;34543:garbage:fdh5654;")
    expect(setting.method(attribute).call).to contain_exactly('example', '34543:garbage:fdh5654')
  end

  it 'does not raise error with nil' do
    setting.method("#{mapped_name}_raw=").call(nil)
    expect(setting.method(attribute).call).to eq([])
  end
end

RSpec.shared_examples 'application settings examples' do
  context 'restricted signup domains' do
    it_behaves_like 'string of domains', :domain_allowlist, :domain_allowlist
  end

  context 'denied signup domains' do
    it_behaves_like 'string of domains', :domain_denylist, :domain_denylist

    it 'sets multiple domain with file' do
      setting.domain_denylist_file = File.open(Rails.root.join('spec/fixtures/', 'domain_denylist.txt'))
      expect(setting.domain_denylist).to contain_exactly('example.com', 'test.com', 'foo.bar')
    end
  end

  context 'outbound_local_requests_whitelist' do
    it_behaves_like 'string of domains', :outbound_local_requests_allowlist, :outbound_local_requests_whitelist

    it 'clears outbound_local_requests_allowlist_arrays memoization' do
      setting.outbound_local_requests_allowlist_raw = 'example.com'

      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly(
        [], [an_object_having_attributes(domain: 'example.com')]
      )

      setting.outbound_local_requests_allowlist_raw = 'gitlab.com'
      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly(
        [], [an_object_having_attributes(domain: 'gitlab.com')]
      )
    end
  end

  context 'outbound_local_requests_allowlist_arrays' do
    it 'separates the IPs and domains' do
      setting.outbound_local_requests_whitelist = [
        '192.168.1.1',
        '127.0.0.0/28',
        '::ffff:a00:2',
        '1:0:0:0:0:0:0:0/124',
        'example.com',
        'subdomain.example.com',
        'www.example.com',
        '::',
        '1::',
        '::1',
        '1:2:3:4:5::7:8',
        '[1:2:3:4:5::7:8]',
        '[2001:db8:85a3:8d3:1319:8a2e:370:7348]:443',
        'www.example2.com:8080',
        'example.com:8080'
      ]

      ip_whitelist = [
        an_object_having_attributes(ip: IPAddr.new('192.168.1.1')),
        an_object_having_attributes(ip: IPAddr.new('127.0.0.0/8')),
        an_object_having_attributes(ip: IPAddr.new('::ffff:a00:2')),
        an_object_having_attributes(ip: IPAddr.new('1:0:0:0:0:0:0:0/124')),
        an_object_having_attributes(ip: IPAddr.new('::')),
        an_object_having_attributes(ip: IPAddr.new('1::')),
        an_object_having_attributes(ip: IPAddr.new('::1')),
        an_object_having_attributes(ip: IPAddr.new('1:2:3:4:5::7:8')),
        an_object_having_attributes(ip: IPAddr.new('[1:2:3:4:5::7:8]')),
        an_object_having_attributes(ip: IPAddr.new('[2001:db8:85a3:8d3:1319:8a2e:370:7348]'), port: 443)
      ]
      domain_whitelist = [
        an_object_having_attributes(domain: 'example.com'),
        an_object_having_attributes(domain: 'subdomain.example.com'),
        an_object_having_attributes(domain: 'www.example.com'),
        an_object_having_attributes(domain: 'www.example2.com', port: 8080),
        an_object_having_attributes(domain: 'example.com', port: 8080)
      ]

      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly(
        ip_whitelist, domain_whitelist
      )
    end
  end

  context 'add_to_outbound_local_requests_whitelist' do
    it 'adds entry to outbound_local_requests_whitelist' do
      setting.outbound_local_requests_whitelist = ['example.com']

      setting.add_to_outbound_local_requests_whitelist(
        ['example.com', '127.0.0.1', 'gitlab.com']
      )

      expect(setting.outbound_local_requests_whitelist).to contain_exactly(
        'example.com',
        '127.0.0.1',
        'gitlab.com'
      )
    end

    it 'clears outbound_local_requests_allowlist_arrays memoization' do
      setting.outbound_local_requests_whitelist = ['example.com']

      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly(
        [],
        [an_object_having_attributes(domain: 'example.com')]
      )

      setting.add_to_outbound_local_requests_whitelist(
        ['example.com', 'gitlab.com']
      )

      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly(
        [],
        [an_object_having_attributes(domain: 'example.com'), an_object_having_attributes(domain: 'gitlab.com')]
      )
    end

    it 'does not raise error with nil' do
      setting.outbound_local_requests_whitelist = nil

      setting.add_to_outbound_local_requests_whitelist(['gitlab.com'])

      expect(setting.outbound_local_requests_whitelist).to contain_exactly('gitlab.com')
      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly(
        [], [an_object_having_attributes(domain: 'gitlab.com')]
      )
    end

    it 'does not raise error with nil' do
      setting.outbound_local_requests_whitelist = nil

      expect(setting.outbound_local_requests_allowlist_arrays).to contain_exactly([], [])
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
    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w(default backup))
      allow(setting).to receive(:repository_storages_weighted).and_return({ 'default' => 20, 'backup' => 80 })
    end

    it 'chooses repository based on weight' do
      picked_storages = { 'default' => 0.0, 'backup' => 0.0 }
      10_000.times { picked_storages[setting.pick_repository_storage] += 1 }

      expect(((picked_storages['default'] / 10_000) * 100).round.to_i).to be_between(19, 21)
      expect(((picked_storages['backup'] / 10_000) * 100).round.to_i).to be_between(79, 81)
    end
  end

  describe '#normalized_repository_storage_weights' do
    using RSpec::Parameterized::TableSyntax

    where(:config_storages, :storages, :normalized) do
      %w(default backup) | { 'default' => 0, 'backup' => 100 }   | { 'default' => 0.0, 'backup' => 1.0 }
      %w(default backup) | { 'default' => 100, 'backup' => 100 } | { 'default' => 0.5, 'backup' => 0.5 }
      %w(default backup) | { 'default' => 20, 'backup' => 80 }   | { 'default' => 0.2, 'backup' => 0.8 }
      %w(default backup) | { 'default' => 0, 'backup' => 0 }     | { 'default' => 0.0, 'backup' => 0.0 }
      %w(default)        | { 'default' => 0, 'backup' => 100 }   | { 'default' => 0.0 }
      %w(default)        | { 'default' => 100, 'backup' => 100 } | { 'default' => 1.0 }
      %w(default)        | { 'default' => 20, 'backup' => 80 }   | { 'default' => 1.0 }
    end

    with_them do
      before do
        allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(config_storages)
        allow(setting).to receive(:repository_storages_weighted).and_return(storages)
      end

      it 'normalizes storage weights' do
        expect(setting.normalized_repository_storage_weights).to eq(normalized)
      end
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
