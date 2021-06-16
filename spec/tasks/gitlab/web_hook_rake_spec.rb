# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:web_hook namespace rake tasks', :silence_stdout do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:project1, reload: true) { create(:project, namespace: group) }
  let_it_be(:project2, reload: true) { create(:project, namespace: group) }
  let_it_be(:other_group_project, reload: true) { create(:project) }

  let(:url) { 'http://example.com' }
  let(:hook_urls) { (project1.hooks + project2.hooks).map(&:url) }
  let(:other_group_hook_urls) { other_group_project.hooks.map(&:url) }

  before do
    Rake.application.rake_require 'tasks/gitlab/web_hook'
  end

  describe 'gitlab:web_hook:add' do
    it 'adds a web hook to all projects' do
      stub_env('URL' => url)
      run_rake_task('gitlab:web_hook:add')

      expect(hook_urls).to contain_exactly(url, url)
      expect(other_group_hook_urls).to contain_exactly(url)
    end

    it 'adds a web hook to projects in the specified namespace' do
      stub_env('URL' => url, 'NAMESPACE' => group.full_path)
      run_rake_task('gitlab:web_hook:add')

      expect(hook_urls).to contain_exactly(url, url)
      expect(other_group_hook_urls).to be_empty
    end

    it 'raises an error if an unknown namespace is specified' do
      stub_env('URL' => url, 'NAMESPACE' => group.full_path)

      group.destroy!

      expect { run_rake_task('gitlab:web_hook:add') }.to raise_error(SystemExit)
    end
  end

  describe 'gitlab:web_hook:rm' do
    let!(:hook1) { create(:project_hook, project: project1, url: url) }
    let!(:hook2) { create(:project_hook, project: project2, url: url) }
    let!(:other_group_hook) { create(:project_hook, project: other_group_project, url: url) }
    let!(:other_url_hook) { create(:project_hook, url: other_url, project: project1) }

    let(:other_url) { 'http://other.example.com' }

    it 'removes a web hook from all projects by URL' do
      stub_env('URL' => url)
      run_rake_task('gitlab:web_hook:rm')

      expect(hook_urls).to contain_exactly(other_url)
      expect(other_group_hook_urls).to be_empty
    end

    it 'removes a web hook from projects in the specified namespace by URL' do
      stub_env('NAMESPACE' => group.full_path, 'URL' => url)
      run_rake_task('gitlab:web_hook:rm')

      expect(hook_urls).to contain_exactly(other_url)
      expect(other_group_hook_urls).to contain_exactly(url)
    end

    it 'raises an error if an unknown namespace is specified' do
      stub_env('URL' => url, 'NAMESPACE' => group.full_path)

      group.destroy!

      expect { run_rake_task('gitlab:web_hook:rm') }.to raise_error(SystemExit)
    end
  end

  describe 'gitlab:web_hook:list' do
    let!(:hook1) { create(:project_hook, project: project1) }
    let!(:hook2) { create(:project_hook, project: project2) }
    let!(:other_group_hook) { create(:project_hook, project: other_group_project) }

    it 'lists all web hooks' do
      expect { run_rake_task('gitlab:web_hook:list') }.to output(/3 webhooks found/).to_stdout
    end

    it 'lists web hooks in a particular namespace' do
      stub_env('NAMESPACE', group.full_path)

      expect { run_rake_task('gitlab:web_hook:list') }.to output(/2 webhooks found/).to_stdout
    end
  end
end
