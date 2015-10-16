require 'spec_helper'

describe Gitlab::Shell do
  let(:project) { double('Project', id: 7, path: 'diaspora') }
  let(:gitlab_shell) { Gitlab::Shell.new }

  before do
    allow(Project).to receive(:find).and_return(project)
  end

  it { is_expected.to respond_to :add_key }
  it { is_expected.to respond_to :remove_key }
  it { is_expected.to respond_to :add_repository }
  it { is_expected.to respond_to :remove_repository }
  it { is_expected.to respond_to :fork_repository }

  it { expect(gitlab_shell.url_to_repo('diaspora')).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "diaspora.git") }

  describe Gitlab::Shell::KeyAdder do
    describe '#add_key' do
      it 'normalizes space characters in the key' do
        io = spy
        adder = described_class.new(io)

        adder.add_key('key-42', "sha-rsa foo\tbar\tbaz")

        expect(io).to have_received(:puts).with("key-42\tsha-rsa foo bar baz")
      end
    end
  end
end
