require 'spec_helper'

describe Gitlab::Git::RevList do
  let(:project) { create(:project, :repository) }
  let(:rev_list) { described_class.new(newrev: 'newrev', path_to_repo: project.repository.path_to_repo) }

  before do
    allow(Gitlab::Git::Env).to receive(:all).and_return({
      GIT_OBJECT_DIRECTORY: 'foo',
      GIT_ALTERNATE_OBJECT_DIRECTORIES: 'bar'
    })
  end

  def stub_popen_rev_list(*additional_args, output:)
    expect(rev_list).to receive(:popen).with([
      Gitlab.config.git.bin_path,
      "--git-dir=#{project.repository.path_to_repo}",
      'rev-list',
      *additional_args
    ],
    nil,
    {
      'GIT_OBJECT_DIRECTORY' => 'foo',
      'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar'
    }).and_return([output, 0])
  end

  context "#new_refs" do
    it 'calls out to `popen`' do
      stub_popen_rev_list('newrev', '--not', '--all', output: "sha1\nsha2")

      expect(rev_list.new_refs).to eq(%w[sha1 sha2])
    end
  end

  context '#new_objects' do
    it 'fetches list of newly pushed objects using rev-list' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2")

      expect(rev_list.new_objects).to eq(%w[sha1 sha2])
    end

    it 'can skip pathless objects' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2 path/to/file")

      expect(rev_list.new_objects(require_path: true)).to eq(%w[sha2])
    end

    it 'can return a lazy enumerator' do
      stub_popen_rev_list('newrev', '--not', '--all', '--objects', output: "sha1\nsha2")

      expect(rev_list.new_objects(lazy: true)).to be_a Enumerator::Lazy
    end

    it 'can accept list of references to exclude' do
      stub_popen_rev_list('newrev', '--not', 'master', '--objects', output: "sha1\nsha2")

      expect(rev_list.new_objects(not_in: ['master'])).to eq(%w[sha1 sha2])
    end

    it 'handles empty list of references to exclude as listing all known objects' do
      stub_popen_rev_list('newrev', '--objects', output: "sha1\nsha2")

      expect(rev_list.new_objects(not_in: [])).to eq(%w[sha1 sha2])
    end
  end

  context '#all_objects' do
    it 'fetches list of all pushed objects using rev-list' do
      stub_popen_rev_list('--all', '--objects', output: "sha1\nsha2")

      expect(rev_list.all_objects.force).to eq(%w[sha1 sha2])
    end
  end

  context "#missed_ref" do
    let(:rev_list) { described_class.new(oldrev: 'oldrev', newrev: 'newrev', path_to_repo: project.repository.path_to_repo) }

    it 'calls out to `popen`' do
      stub_popen_rev_list('--max-count=1', 'oldrev', '^newrev', output: "sha1\nsha2")

      expect(rev_list.missed_ref).to eq(%w[sha1 sha2])
    end
  end
end
