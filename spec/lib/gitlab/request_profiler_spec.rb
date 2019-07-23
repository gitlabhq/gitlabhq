require 'spec_helper'

describe Gitlab::RequestProfiler do
  describe '.profile_token' do
    it 'returns a token' do
      expect(described_class.profile_token).to be_present
    end

    it 'caches the token' do
      expect(Rails.cache).to receive(:fetch).with('profile-token')

      described_class.profile_token
    end
  end

  context 'with temporary PROFILES_DIR' do
    let(:tmpdir) { Dir.mktmpdir('profiler-test') }
    let(:profile_name) { '|api|v4|version.txt_1562854738_memory.html' }
    let(:profile_path) { File.join(tmpdir, profile_name) }

    before do
      stub_const('Gitlab::RequestProfiler::PROFILES_DIR', tmpdir)
      FileUtils.touch(profile_path)
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    describe '.remove_all_profiles' do
      it 'removes Gitlab::RequestProfiler::PROFILES_DIR directory' do
        described_class.remove_all_profiles

        expect(Dir.exist?(tmpdir)).to be false
      end
    end

    describe '.all' do
      subject { described_class.all }

      it 'returns all profiles' do
        expect(subject.map(&:name)).to contain_exactly(profile_name)
      end
    end

    describe '.find' do
      subject { described_class.find(profile_name) }

      it 'returns all profiles' do
        expect(subject.name).to eq(profile_name)
      end
    end
  end
end
