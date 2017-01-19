# coding: utf-8
require 'spec_helper'

describe Gitlab::Regex, lib: true do
  describe 'project path regex' do
    it { expect('gitlab-ce').to match(Gitlab::Regex.project_path_regex) }
    it { expect('gitlab_git').to match(Gitlab::Regex.project_path_regex) }
    it { expect('_underscore.js').to match(Gitlab::Regex.project_path_regex) }
    it { expect('100px.com').to match(Gitlab::Regex.project_path_regex) }
    it { expect('?gitlab').not_to match(Gitlab::Regex.project_path_regex) }
    it { expect('git lab').not_to match(Gitlab::Regex.project_path_regex) }
    it { expect('gitlab.git').not_to match(Gitlab::Regex.project_path_regex) }
  end

  describe 'project name regex' do
    it { expect('gitlab-ce').to match(Gitlab::Regex.project_name_regex) }
    it { expect('GitLab CE').to match(Gitlab::Regex.project_name_regex) }
    it { expect('100 lines').to match(Gitlab::Regex.project_name_regex) }
    it { expect('gitlab.git').to match(Gitlab::Regex.project_name_regex) }
    it { expect('Český název').to match(Gitlab::Regex.project_name_regex) }
    it { expect('Dash – is this').to match(Gitlab::Regex.project_name_regex) }
    it { expect('?gitlab').not_to match(Gitlab::Regex.project_name_regex) }
  end

  describe 'file name regex' do
    it { expect('foo@bar').to match(Gitlab::Regex.file_name_regex) }
  end

  describe 'file path regex' do
    it { expect('foo@/bar').to match(Gitlab::Regex.file_path_regex) }
  end

  describe 'environment slug regex' do
    def be_matched
      match(Gitlab::Regex.environment_slug_regex)
    end

    it { expect('foo').to be_matched }
    it { expect('foo-1').to be_matched }

    it { expect('FOO').not_to be_matched }
    it { expect('foo/1').not_to be_matched }
    it { expect('foo.1').not_to be_matched }
    it { expect('foo*1').not_to be_matched }
    it { expect('9foo').not_to be_matched }
    it { expect('foo-').not_to be_matched }
  end
end
