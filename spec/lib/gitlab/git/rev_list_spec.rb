require 'spec_helper'

describe Gitlab::Git::RevList do
  let(:repository) { create(:project, :repository).repository.raw }
  let(:rev_list) { described_class.new(repository, newrev: 'newrev') }

  def args_for_popen(args_list)
    [Gitlab.config.git.bin_path, 'rev-list', *args_list]
  end

  def stub_popen_rev_list(*additional_args, with_lazy_block: true, output:)
    repo_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access { repository.path }

    params = [
      args_for_popen(additional_args),
      repo_path,
      {},
      hash_including(lazy_block: with_lazy_block ? anything : nil)
    ]

    expect(repository).to receive(:popen).with(*params) do |*_, lazy_block:|
      output = lazy_block.call(output.lines.lazy.map(&:chomp)) if with_lazy_block

      [output, 0]
    end
  end

  context "#new_refs" do
    it 'calls out to `popen`' do
      stub_popen_rev_list('newrev', '--not', '--all', with_lazy_block: false, output: "sha1\nsha2")

      expect(rev_list.new_refs).to eq(%w[sha1 sha2])
    end
  end
end
