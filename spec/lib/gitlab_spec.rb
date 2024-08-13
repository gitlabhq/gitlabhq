# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab, feature_category: :shared do
  %w[root extensions ee? jh?].each do |method_name|
    it "delegates #{method_name} to GitlabEdition" do
      expect(GitlabEdition).to receive(method_name)

      described_class.public_send(method_name)
    end
  end

  %w[ee jh].each do |method_name|
    it "delegates #{method_name} to GitlabEdition" do
      expect(GitlabEdition).to receive(method_name)

      described_class.public_send(method_name) {}
    end
  end

  describe '.revision' do
    let(:cmd) { %W[#{described_class.config.git.bin_path} log --pretty=format:%h --abbrev=11 -n 1] }

    around do |example|
      described_class.instance_variable_set(:@_revision, nil)
      example.run
      described_class.instance_variable_set(:@_revision, nil)
    end

    context 'when a REVISION file exists' do
      before do
        expect(File).to receive(:exist?)
                          .with(described_class.root.join('REVISION'))
                          .and_return(true)
      end

      it 'returns the actual Git revision' do
        expect_file_read(described_class.root.join('REVISION'), content: "abc123\n")

        expect(described_class.revision).to eq('abc123')
      end

      it 'memoizes the revision' do
        stub_file_read(described_class.root.join('REVISION'), content: "abc123\n")

        expect(File).to receive(:read)
          .once
          .with(described_class.root.join('REVISION'))

        2.times { described_class.revision }
      end
    end

    context 'when no REVISION file exist' do
      context 'when the Git command succeeds' do
        before do
          expect(Gitlab::Popen).to receive(:popen_with_detail)
                                     .with(cmd)
                                     .and_return(Gitlab::Popen::Result.new(cmd, 'abc123', '', double(success?: true)))
        end

        it 'returns the actual Git revision' do
          expect(described_class.revision).to eq('abc123')
        end
      end

      context 'when the Git command fails' do
        before do
          expect(Gitlab::Popen).to receive(:popen_with_detail)
                                     .with(cmd)
                                     .and_return(Gitlab::Popen::Result.new(cmd, '', 'fatal: Not a git repository', double('Process::Status', success?: false)))
        end

        it 'returns "Unknown"' do
          expect(described_class.revision).to eq('Unknown')
        end
      end
    end
  end

  describe '.com?' do
    context 'when not simulating SaaS' do
      before do
        stub_env('GITLAB_SIMULATE_SAAS', '0')
      end

      it "is true when on #{Gitlab::Saas.com_url}" do
        stub_config_setting(url: Gitlab::Saas.com_url)

        expect(described_class.com?).to eq true
      end

      it "is true when on #{Gitlab::Saas.staging_com_url}" do
        stub_config_setting(url: Gitlab::Saas.staging_com_url)

        expect(described_class.com?).to eq true
      end

      it 'is true when on other gitlab subdomain' do
        url_with_subdomain = Gitlab::Saas.com_url.gsub('https://', 'https://example.')
        stub_config_setting(url: url_with_subdomain)

        expect(described_class.com?).to eq true
      end

      it 'is true when on other gitlab subdomain with hyphen' do
        url_with_subdomain = Gitlab::Saas.com_url.gsub('https://', 'https://test-example.')
        stub_config_setting(url: url_with_subdomain)

        expect(described_class.com?).to eq true
      end

      it 'is false when not on GitLab.com' do
        stub_config_setting(url: 'http://example.com')

        expect(described_class.com?).to eq false
      end
    end

    it 'is true when GITLAB_SIMULATE_SAAS is true and in development' do
      stub_rails_env('development')
      stub_env('GITLAB_SIMULATE_SAAS', '1')

      expect(described_class.com?).to eq true
    end

    it 'is false when GITLAB_SIMULATE_SAAS is true and in test' do
      stub_env('GITLAB_SIMULATE_SAAS', '1')

      expect(described_class.com?).to eq false
    end
  end

  describe '.com_except_jh?' do
    subject { described_class.com_except_jh? }

    before do
      allow(described_class).to receive(:com?).and_return(com?)
      allow(described_class).to receive(:jh?).and_return(jh?)
    end

    using RSpec::Parameterized::TableSyntax

    where(:com?, :jh?, :expected) do
      true  | true  | false
      true  | false | true
      false | true  | false
      false | false | false
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe '.com' do
    subject { described_class.com { true } }

    before do
      allow(described_class).to receive(:com?).and_return(gl_com)
    end

    context 'when on GitLab.com' do
      let(:gl_com) { true }

      it { is_expected.to be true }
    end

    context 'when not on GitLab.com' do
      let(:gl_com) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '.staging?' do
    subject { described_class.staging? }

    it "is false when on #{Gitlab::Saas.com_url}" do
      stub_config_setting(url: Gitlab::Saas.com_url)

      expect(subject).to eq false
    end

    it "is true when on #{Gitlab::Saas.staging_com_url}" do
      stub_config_setting(url: Gitlab::Saas.staging_com_url)

      expect(subject).to eq true
    end

    it 'is false when not on staging' do
      stub_config_setting(url: 'https://example.gitlab.com')

      expect(subject).to eq false
    end
  end

  describe '.canary?' do
    it 'is true when CANARY env var is set to true' do
      stub_env('CANARY', '1')

      expect(described_class.canary?).to eq true
    end

    it 'is false when CANARY env var is set to false' do
      stub_env('CANARY', '0')

      expect(described_class.canary?).to eq false
    end
  end

  describe '.com_and_canary?' do
    it 'is true when on .com and canary' do
      allow(described_class).to receive_messages(com?: true, canary?: true)

      expect(described_class.com_and_canary?).to eq true
    end

    it 'is false when on .com but not on canary' do
      allow(described_class).to receive_messages(com?: true, canary?: false)

      expect(described_class.com_and_canary?).to eq false
    end
  end

  describe '.com_but_not_canary?' do
    it 'is false when on .com and canary' do
      allow(described_class).to receive_messages(com?: true, canary?: true)

      expect(described_class.com_but_not_canary?).to eq false
    end

    it 'is true when on .com but not on canary' do
      allow(described_class).to receive_messages(com?: true, canary?: false)

      expect(described_class.com_but_not_canary?).to eq true
    end
  end

  describe '.org_or_com?' do
    it 'is true when on .com' do
      allow(described_class).to receive_messages(com?: true, org?: false)

      expect(described_class.org_or_com?).to eq true
    end

    it 'is true when org' do
      allow(described_class).to receive_messages(com?: false, org?: true)

      expect(described_class.org_or_com?).to eq true
    end

    it 'is false when not dev, org or com' do
      allow(described_class).to receive_messages(com?: false, org?: false)

      expect(described_class.org_or_com?).to eq false
    end
  end

  describe '.simulate_com?' do
    subject { described_class.simulate_com? }

    context 'when GITLAB_SIMULATE_SAAS is true' do
      before do
        stub_env('GITLAB_SIMULATE_SAAS', '1')
      end

      it 'is false when test env' do
        expect(subject).to eq false
      end

      it 'is true when dev env' do
        stub_rails_env('development')

        expect(subject).to eq true
      end

      it 'is false when env is not dev' do
        stub_rails_env('production')

        expect(subject).to eq false
      end
    end

    context 'when GITLAB_SIMULATE_SAAS is false' do
      before do
        stub_env('GITLAB_SIMULATE_SAAS', '0')
      end

      it 'is false when test env' do
        expect(subject).to eq false
      end

      it 'is false when dev env' do
        stub_rails_env('development')

        expect(subject).to eq false
      end

      it 'is false when env is not dev or test' do
        stub_rails_env('production')

        expect(subject).to eq false
      end
    end
  end

  describe '.dev_or_test_env?' do
    subject { described_class.dev_or_test_env? }

    it 'is true when test env' do
      expect(subject).to eq true
    end

    it 'is true when dev env' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

      expect(subject).to eq true
    end

    it 'is false when env is not dev or test' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

      expect(subject).to eq false
    end
  end

  describe '.http_proxy_env?' do
    it 'returns true when lower case https' do
      stub_env('https_proxy', 'https://my.proxy')

      expect(described_class.http_proxy_env?).to eq(true)
    end

    it 'returns true when upper case https' do
      stub_env('HTTPS_PROXY', 'https://my.proxy')

      expect(described_class.http_proxy_env?).to eq(true)
    end

    it 'returns true when lower case http' do
      stub_env('http_proxy', 'http://my.proxy')

      expect(described_class.http_proxy_env?).to eq(true)
    end

    it 'returns true when upper case http' do
      stub_env('HTTP_PROXY', 'http://my.proxy')

      expect(described_class.http_proxy_env?).to eq(true)
    end

    it 'returns false when not set' do
      expect(described_class.http_proxy_env?).to eq(false)
    end
  end

  describe '.maintenance_mode?' do
    it 'returns true when maintenance mode is enabled' do
      stub_maintenance_mode_setting(true)

      expect(described_class.maintenance_mode?).to eq(true)
    end

    it 'returns false when maintenance mode is disabled' do
      stub_maintenance_mode_setting(false)

      expect(described_class.maintenance_mode?).to eq(false)
    end

    it 'returns false when maintenance mode column is not present' do
      stub_maintenance_mode_setting(true)

      allow(::Gitlab::CurrentSettings.current_application_settings)
        .to receive(:respond_to?)
        .with(:maintenance_mode, false)
        .and_return(false)

      expect(described_class.maintenance_mode?).to eq(false)
    end
  end

  describe '.next_rails?' do
    around do |example|
      described_class.instance_variable_set(:@next_bundle_gemfile, nil)

      example.run
    ensure
      described_class.instance_variable_set(:@next_bundle_gemfile, nil)
    end

    where(:bundle_gemfile, :expected_result) do
      [
        [nil, false],
        ['Gemfile.another', false],
        ['Gemfile.next', true]
      ]
    end

    with_them do
      it 'returns whether BUNDLE_GEMFILE points to Gemfile.next' do
        stub_env('BUNDLE_GEMFILE', bundle_gemfile)

        expect(described_class.next_rails?).to eq(expected_result)
      end
    end
  end
end
