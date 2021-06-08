# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:update_project_templates rake task', :silence_stdout do
  let!(:tmpdir) { Dir.mktmpdir }

  before do
    Rake.application.rake_require 'tasks/gitlab/update_templates'
    create(:admin)

    allow(Gitlab::ProjectTemplate)
      .to receive(:archive_directory)
        .and_return(Pathname.new(tmpdir))

    # Gitlab::HTTP resolves the domain to an IP prior to WebMock taking effect, hence the wildcard
    stub_request(:get, %r{^https://.*/api/v4/projects/gitlab-org%2Fproject-templates%2Frails/repository/commits\?page=1&per_page=1})
      .to_return(
        status: 200,
        body: [{ id: '67812735b83cb42710f22dc98d73d42c8bf4d907' }].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
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
