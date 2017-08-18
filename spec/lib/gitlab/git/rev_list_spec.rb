require 'spec_helper'

describe Gitlab::Git::RevList do
  let(:project) { create(:project, :repository) }

  before do
    expect(Gitlab::Git::Env).to receive(:all).and_return({
      GIT_OBJECT_DIRECTORY: 'foo',
      GIT_ALTERNATE_OBJECT_DIRECTORIES: 'bar'
    })
  end

  context "#new_refs" do
    let(:rev_list) { described_class.new(newrev: 'newrev', path_to_repo: project.repository.path_to_repo) }

    it 'calls out to `popen`' do
      expect(Gitlab::Popen).to receive(:popen).with([
        Gitlab.config.git.bin_path,
        "--git-dir=#{project.repository.path_to_repo}",
        'rev-list',
        'newrev',
        '--not',
        '--all'
      ],
      nil,
      {
        'GIT_OBJECT_DIRECTORY' => 'foo',
        'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar'
      }).and_return(["sha1\nsha2", 0])

      expect(rev_list.new_refs).to eq(%w[sha1 sha2])
    end
  end

  context "#missed_ref" do
    let(:rev_list) { described_class.new(oldrev: 'oldrev', newrev: 'newrev', path_to_repo: project.repository.path_to_repo) }

    it 'calls out to `popen`' do
      expect(Gitlab::Popen).to receive(:popen).with([
        Gitlab.config.git.bin_path,
        "--git-dir=#{project.repository.path_to_repo}",
        'rev-list',
        '--max-count=1',
        'oldrev',
        '^newrev'
      ],
      nil,
      {
        'GIT_OBJECT_DIRECTORY' => 'foo',
        'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar'
      }).and_return(["sha1\nsha2", 0])

      expect(rev_list.missed_ref).to eq(%w[sha1 sha2])
    end
  end
end
