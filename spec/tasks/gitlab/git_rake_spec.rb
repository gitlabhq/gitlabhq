# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:git rake tasks', :silence_stdout do
  let(:base_path) { 'tmp/tests/default_storage' }
  let!(:project) { create(:project, :repository) }

  before do
    Rake.application.rake_require 'tasks/gitlab/git'

    stub_warn_user_is_not_gitlab
  end

  describe 'fsck' do
    it 'outputs the integrity check for a repo' do
      expect { run_rake_task('gitlab:git:fsck') }.to output(/Performed integrity check for/).to_stdout
    end
  end

  describe 'checksum_projects' do
    it 'outputs the checksum for a repo' do
      expected = /#{project.id},#{project.repository.checksum}/

      expect { run_rake_task('gitlab:git:checksum_projects') }.to output(expected).to_stdout
    end

    it 'outputs blank checksum for no repo' do
      no_repo = create(:project)

      expected = /#{no_repo.id},$/

      expect { run_rake_task('gitlab:git:checksum_projects') }.to output(expected).to_stdout
    end

    it 'outputs zeroes for empty repo' do
      empty_repo = create(:project, :empty_repo)

      expected = /#{empty_repo.id},0000000000000000000000000000000000000000/

      expect { run_rake_task('gitlab:git:checksum_projects') }.to output(expected).to_stdout
    end

    it 'outputs errors' do
      allow_next_found_instance_of(Project) do |project|
        allow(project).to receive(:repo_exists?).and_raise('foo')
      end

      expected = /#{project.id},Ignored error: foo/

      expect { run_rake_task('gitlab:git:checksum_projects') }.to output(expected).to_stdout
    end
  end
end
