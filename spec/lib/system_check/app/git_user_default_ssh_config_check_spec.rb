require 'spec_helper'

describe SystemCheck::App::GitUserDefaultSSHConfigCheck do
  let(:username) { '_this_user_will_not_exist_unless_it_is_stubbed' }
  let(:base_dir) { Dir.mktmpdir }
  let(:home_dir) { File.join(base_dir, "/var/lib/#{username}") }
  let(:ssh_dir) { File.join(home_dir, '.ssh') }
  let(:forbidden_file) { 'id_rsa' }

  before do
    allow(Gitlab.config.gitlab).to receive(:user).and_return(username)
  end

  after do
    FileUtils.rm_rf(base_dir)
  end

  it 'only whitelists safe files' do
    expect(described_class::WHITELIST).to contain_exactly(
      'authorized_keys',
      'authorized_keys2',
      'authorized_keys.lock',
      'known_hosts'
    )
  end

  describe '#skip?' do
    subject { described_class.new.skip? }

    where(user_exists: [true, false], home_dir_exists: [true, false])

    with_them do
      let(:expected_result) { !user_exists || !home_dir_exists }

      before do
        stub_user if user_exists
        stub_home_dir if home_dir_exists
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#check?' do
    subject { described_class.new.check? }

    before do
      stub_user
    end

    it 'fails if a forbidden file exists' do
      stub_ssh_file(forbidden_file)

      is_expected.to be_falsy
    end

    it "succeeds if the SSH directory doesn't exist" do
      FileUtils.rm_rf(ssh_dir)

      is_expected.to be_truthy
    end

    it 'succeeds if all the whitelisted files exist' do
      described_class::WHITELIST.each do |filename|
        stub_ssh_file(filename)
      end

      is_expected.to be_truthy
    end
  end

  def stub_user
    allow(File).to receive(:expand_path).with("~#{username}").and_return(home_dir)
  end

  def stub_home_dir
    FileUtils.mkdir_p(home_dir)
  end

  def stub_ssh_file(filename)
    FileUtils.mkdir_p(ssh_dir)
    FileUtils.touch(File.join(ssh_dir, filename))
  end
end
