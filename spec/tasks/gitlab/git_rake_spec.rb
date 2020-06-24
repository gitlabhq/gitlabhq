# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:git rake tasks' do
  let(:base_path) { 'tmp/tests/default_storage' }
  let!(:project) { create(:project, :repository) }

  before do
    Rake.application.rake_require 'tasks/gitlab/git'

    allow_any_instance_of(String).to receive(:color) { |string, _color| string }

    stub_warn_user_is_not_gitlab
  end

  describe 'fsck' do
    it 'outputs the integrity check for a repo' do
      expect { run_rake_task('gitlab:git:fsck') }.to output(/Performed integrity check for/).to_stdout
    end
  end
end
