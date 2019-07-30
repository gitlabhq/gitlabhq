# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:update_project_templates rake task' do
  let!(:tmpdir) { Dir.mktmpdir }

  before do
    Rake.application.rake_require 'tasks/gitlab/update_templates'
    create(:admin)
    allow(Gitlab::ProjectTemplate)
      .to receive(:archive_directory)
        .and_return(Pathname.new(tmpdir))
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it 'updates valid project templates' do
    expect { run_rake_task('gitlab:update_project_templates', ['rails']) }
      .to change { Dir.entries(tmpdir) }
        .by(['rails.tar.gz'])
  end
end
