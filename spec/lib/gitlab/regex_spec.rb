require 'spec_helper'

describe Gitlab::Regex do
  describe 'path regex' do
    it { 'gitlab-ce'.should match(Gitlab::Regex.path_regex) }
    it { 'gitlab_git'.should match(Gitlab::Regex.path_regex) }
    it { '_underscore.js'.should match(Gitlab::Regex.path_regex) }
    it { '100px.com'.should match(Gitlab::Regex.path_regex) }
    it { '?gitlab'.should_not match(Gitlab::Regex.path_regex) }
    it { 'git lab'.should_not match(Gitlab::Regex.path_regex) }
    it { 'gitlab.git'.should_not match(Gitlab::Regex.path_regex) }
  end

  describe 'project name regex' do
    it { 'gitlab-ce'.should match(Gitlab::Regex.project_name_regex) }
    it { 'GitLab CE'.should match(Gitlab::Regex.project_name_regex) }
    it { '100 lines'.should match(Gitlab::Regex.project_name_regex) }
    it { 'gitlab.git'.should match(Gitlab::Regex.project_name_regex) }
    it { '?gitlab'.should_not match(Gitlab::Regex.project_name_regex) }
  end
end
