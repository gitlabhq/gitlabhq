# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab do
  describe '.root' do
    it 'returns the root path of the app' do
      expect(described_class.root).to eq(Pathname.new(File.expand_path('../..', __dir__)))
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

    it 'is false when not on GitLab.com' do
      stub_config_setting(url: 'http://example.com')

      expect(described_class.com?).to eq false
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

  describe '.dev_env_org_or_com?' do
    it 'is true when on .com' do
      allow(described_class).to receive_messages(com?: true, org?: false)

      expect(described_class.dev_env_org_or_com?).to eq true
    end

    it 'is true when org' do
      allow(described_class).to receive_messages(com?: false, org?: true)

      expect(described_class.dev_env_org_or_com?).to eq true
    end

    it 'is true when dev env' do
      allow(described_class).to receive_messages(com?: false, org?: false)
      stub_rails_env('development')

      expect(described_class.dev_env_org_or_com?).to eq true
    end

    it 'is false when not dev, org or com' do
      allow(described_class).to receive_messages(com?: false, org?: false)

      expect(described_class.dev_env_org_or_com?).to eq false
    end
  end

  describe '.dev_env_or_com?' do
    it 'is true when on .com' do
      allow(described_class).to receive(:com?).and_return(true)

      expect(described_class.dev_env_or_com?).to eq true
    end

    it 'is true when dev env' do
      allow(described_class).to receive(:com?).and_return(false)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

      expect(described_class.dev_env_or_com?).to eq true
    end

    it 'is false when not dev or com' do
      allow(described_class).to receive(:com?).and_return(false)

      expect(described_class.dev_env_or_com?).to eq false
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

  describe 'ee? and jh?' do
    before do
      # Make sure the ENV is clean
      stub_env('FOSS_ONLY', nil)
      stub_env('EE_ONLY', nil)

      described_class.instance_variable_set(:@is_ee, nil)
      described_class.instance_variable_set(:@is_jh, nil)
    end

    after do
      described_class.instance_variable_set(:@is_ee, nil)
      described_class.instance_variable_set(:@is_jh, nil)
    end

    def stub_path(*paths, **arguments)
      root = Pathname.new('dummy')
      pathname = double(:path, **arguments)

      allow(described_class)
        .to receive(:root)
        .and_return(root)

      allow(root).to receive(:join)

      paths.each do |path|
        allow(root)
          .to receive(:join)
          .with(path)
          .and_return(pathname)
      end
    end

    describe '.ee?' do
      context 'for EE' do
        before do
          stub_path('ee/app/models/license.rb', exist?: true)
        end

        context 'when using FOSS_ONLY=1' do
          before do
            stub_env('FOSS_ONLY', '1')
          end

          it 'returns not to be EE' do
            expect(described_class).not_to be_ee
          end
        end

        context 'when using FOSS_ONLY=0' do
          before do
            stub_env('FOSS_ONLY', '0')
          end

          it 'returns to be EE' do
            expect(described_class).to be_ee
          end
        end

        context 'when using default FOSS_ONLY' do
          it 'returns to be EE' do
            expect(described_class).to be_ee
          end
        end
      end

      context 'for CE' do
        before do
          stub_path('ee/app/models/license.rb', exist?: false)
        end

        it 'returns not to be EE' do
          expect(described_class).not_to be_ee
        end
      end
    end

    describe '.jh?' do
      context 'for JH' do
        before do
          stub_path(
            'ee/app/models/license.rb',
            'jh',
            exist?: true)
        end

        context 'when using default FOSS_ONLY and EE_ONLY' do
          it 'returns to be JH' do
            expect(described_class).to be_jh
          end
        end

        context 'when using FOSS_ONLY=1' do
          before do
            stub_env('FOSS_ONLY', '1')
          end

          it 'returns not to be JH' do
            expect(described_class).not_to be_jh
          end
        end

        context 'when using EE_ONLY=1' do
          before do
            stub_env('EE_ONLY', '1')
          end

          it 'returns not to be JH' do
            expect(described_class).not_to be_jh
          end
        end
      end
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
end
