require 'spec_helper'

describe Gitlab::Git::RevList do
  let(:repository) { create(:project, :repository).repository.raw }
  let(:rev_list) { described_class.new(repository, newrev: 'newrev') }
  let(:env_hash) do
    {
      'GIT_OBJECT_DIRECTORY' => 'foo',
      'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar'
    }
  end
  let(:command_env) { { 'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'foo:bar' } }

  before do
    allow(Gitlab::Git::Env).to receive(:all).and_return(env_hash)
  end

  def args_for_popen(args_list)
    [Gitlab.config.git.bin_path, 'rev-list', *args_list]
  end

  def stub_popen_rev_list(*additional_args, with_lazy_block: true, output:)
    params = [
      args_for_popen(additional_args),
      repository.path,
      command_env,
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

  context '#new_objects' do
    it 'fetches list of newly pushed objects using rev-list' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2")

      expect { |b| rev_list.new_objects(&b) }.to yield_with_args(%w[sha1 sha2])
    end

    it 'can skip pathless objects' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2 path/to/file")

      expect { |b| rev_list.new_objects(require_path: true, &b) }.to yield_with_args(%w[sha2])
    end

    it 'can handle non utf-8 paths' do
      non_utf_char = [0x89].pack("c*").force_encoding("UTF-8")
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha2 πå†h/†ø/ƒîlé#{non_utf_char}\nsha1")

      rev_list.new_objects(require_path: true) do |object_ids|
        expect(object_ids.force).to eq(%w[sha2])
      end
    end

    it 'can yield a lazy enumerator' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2")

      rev_list.new_objects do |object_ids|
        expect(object_ids).to be_a Enumerator::Lazy
      end
    end

    it 'returns the result of the block when given' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2")

      objects = rev_list.new_objects do |object_ids|
        object_ids.first
      end

      expect(objects).to eq 'sha1'
    end

    it 'can accept list of references to exclude' do
      stub_popen_rev_list('newrev', '--not', 'master', '--objects', output: "sha1\nsha2")

      expect { |b| rev_list.new_objects(not_in: ['master'], &b) }.to yield_with_args(%w[sha1 sha2])
    end

    it 'handles empty list of references to exclude as listing all known objects' do
      stub_popen_rev_list('newrev', '--objects', output: "sha1\nsha2")

      expect { |b| rev_list.new_objects(not_in: [], &b) }.to yield_with_args(%w[sha1 sha2])
    end
  end

  context '#all_objects' do
    it 'fetches list of all pushed objects using rev-list' do
      stub_popen_rev_list('--all', '--objects', output: "sha1\nsha2")

      expect { |b| rev_list.all_objects(&b) }.to yield_with_args(%w[sha1 sha2])
    end
  end

  context "#missed_ref" do
    let(:rev_list) { described_class.new(repository, oldrev: 'oldrev', newrev: 'newrev') }

    it 'calls out to `popen`' do
      stub_popen_rev_list('--max-count=1', 'oldrev', '^newrev', with_lazy_block: false, output: "sha1\nsha2")

      expect(rev_list.missed_ref).to eq(%w[sha1 sha2])
    end
  end
end
