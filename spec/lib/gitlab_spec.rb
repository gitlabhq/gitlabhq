require 'fast_spec_helper'

require_dependency 'gitlab'

describe Gitlab do
  describe '.root' do
    it 'returns the root path of the app' do
      expect(described_class.root).to eq(Pathname.new(File.expand_path('../..', __dir__)))
    end
  end
  describe '.revision' do
    let(:cmd) { %W[#{described_class.config.git.bin_path} log --pretty=format:%h -n 1] }

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
        expect(File).to receive(:read)
          .with(described_class.root.join('REVISION'))
          .and_return("abc123\n")

        expect(described_class.revision).to eq('abc123')
      end

      it 'memoizes the revision' do
        expect(File).to receive(:read)
          .once
          .with(described_class.root.join('REVISION'))
          .and_return("abc123\n")

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
    it 'is true when on GitLab.com' do
      stub_config_setting(url: 'https://gitlab.com')

      expect(described_class.com?).to eq true
    end

    it 'is true when on staging' do
      stub_config_setting(url: 'https://staging.gitlab.com')

      expect(described_class.com?).to eq true
    end

    it 'is true when on other gitlab subdomain' do
      stub_config_setting(url: 'https://example.gitlab.com')

      expect(described_class.com?).to eq true
    end

    it 'is false when not on GitLab.com' do
      stub_config_setting(url: 'http://example.com')

      expect(described_class.com?).to eq false
    end
  end
end
