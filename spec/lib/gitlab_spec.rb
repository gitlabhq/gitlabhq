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

  describe '.final_release?' do
    subject { described_class.final_release? }

    context 'returns the corrent boolean value' do
      it 'is false for a pre release' do
        stub_const('Gitlab::VERSION', '11.0.0-pre')

        expect(subject).to be false
      end

      it 'is false for a release candidate' do
        stub_const('Gitlab::VERSION', '11.0.0-rc2')

        expect(subject).to be false
      end

      it 'is true for a final release' do
        stub_const('Gitlab::VERSION', '11.0.2')

        expect(subject).to be true
      end
    end
  end

  describe '.minor_release' do
    subject { described_class.minor_release }

    it 'returns the minor release of the full GitLab version' do
      stub_const('Gitlab::VERSION', '11.0.1-rc3')

      expect(subject).to eql '11.0'
    end
  end

  describe '.previous_release' do
    subject { described_class.previous_release }

    context 'it should return the previous release' do
      it 'returns the previous major version when GitLab major version is not final' do
        stub_const('Gitlab::VERSION', '11.0.1-pre')

        expect(subject).to eql '10'
      end

      it 'returns the current minor version when the GitLab patch version is RC and > 0' do
        stub_const('Gitlab::VERSION', '11.2.1-rc3')

        expect(subject).to eql '11.2'
      end

      it 'returns the previous minor version when the GitLab patch version is RC and 0' do
        stub_const('Gitlab::VERSION', '11.2.0-rc3')

        expect(subject).to eql '11.1'
      end
    end
  end

  describe '.new_major_release?' do
    subject { described_class.new_major_release? }

    context 'returns the corrent boolean value' do
      it 'is true when the minor version is 0 and the patch is a pre release' do
        stub_const('Gitlab::VERSION', '11.0.1-pre')

        expect(subject).to be true
      end

      it 'is false when the minor version is above 0' do
        stub_const('Gitlab::VERSION', '11.2.1-rc3')

        expect(subject).to be false
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
