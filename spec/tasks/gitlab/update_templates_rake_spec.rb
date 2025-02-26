# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:update_templates rake task', :silence_stdout, feature_category: :importers do
  before do
    Rake.application.rake_require 'tasks/gitlab/update_templates'
  end

  describe '.update_project_templates' do
    let!(:tmpdir) { Dir.mktmpdir }
    let(:template) { Gitlab::ProjectTemplate.find(:rails) }

    before do
      admin = create(:admin)
      create(:key, user: admin)

      allow(Gitlab::ProjectTemplate)
        .to receive(:archive_directory)
          .and_return(Pathname.new(tmpdir))

      # Gitlab::HTTP resolves the domain to an IP prior to WebMock taking effect, hence the wildcard
      stub_request(:get, %r{^https://.*/api/v4/projects/#{template.uri_encoded_project_path}/repository/commits\?page=1&per_page=1})
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
      expect(Gitlab::TaskHelpers).to receive(:run_command!).with(anything).exactly(6).times.and_call_original
      expect(Gitlab::TaskHelpers).to receive(:run_command!).with(%w[git push -u origin master])

      expect { run_rake_task('gitlab:update_project_templates', [template.name]) }
        .to change { Dir.entries(tmpdir) }
          .by(["#{template.name}.tar.gz"])
    end
  end

  describe '#clone_repository' do
    let(:repo_url) { "https://test.com/example/text.git" }
    let(:template) do
      Struct.new(:repo_url, :cleanup_regex).new(
        repo_url,
        /(\.{1,2}|LICENSE|Global|\.test)\z/
      )
    end

    let(:dir) { Rails.root.join('vendor/text').to_s }
    let(:kernel_system_call_params) { "git clone #{repo_url} --depth=1 --branch=master #{dir}" }

    before do
      stub_const('TEMPLATE_DATA', [template])
      allow(main_object).to receive(:system).with(kernel_system_call_params).and_return(false)
      allow(FileUtils).to receive(:rm_rf).and_call_original
    end

    it 'calls FileUtils.rm_rf to remove directory' do
      expect(FileUtils).to receive(:rm_rf).with(dir)

      run_rake_task('gitlab:update_templates')
    end
  end
end
