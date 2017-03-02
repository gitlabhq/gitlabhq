# coding: utf-8
require 'spec_helper'

describe Gitlab::Regex, lib: true do
  describe '.project_path_regex' do
    subject { described_class.project_path_regex }

    it { is_expected.to match('gitlab-ce') }
    it { is_expected.to match('gitlab_git') }
    it { is_expected.to match('_underscore.js') }
    it { is_expected.to match('100px.com') }
    it { is_expected.not_to match('?gitlab') }
    it { is_expected.not_to match('git lab') }
    it { is_expected.not_to match('gitlab.git') }
  end

  describe '.project_name_regex' do
    subject { described_class.project_name_regex }

    it { is_expected.to match('gitlab-ce') }
    it { is_expected.to match('GitLab CE') }
    it { is_expected.to match('100 lines') }
    it { is_expected.to match('gitlab.git') }
    it { is_expected.to match('Český název') }
    it { is_expected.to match('Dash – is this') }
    it { is_expected.not_to match('?gitlab') }
  end

  describe '.file_name_regex' do
    subject { described_class.file_name_regex }

    it { is_expected.to match('foo@bar') }
  end

  describe '.file_path_regex' do
    subject { described_class.file_path_regex }

    it { is_expected.to match('foo@/bar') }
  end

  describe '.environment_slug_regex' do
    subject { described_class.environment_slug_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('foo-1') }
    it { is_expected.not_to match('FOO') }
    it { is_expected.not_to match('foo/1') }
    it { is_expected.not_to match('foo.1') }
    it { is_expected.not_to match('foo*1') }
    it { is_expected.not_to match('9foo') }
    it { is_expected.not_to match('foo-') }
  end

  describe 'FULL_NAMESPACE_REGEX_STR' do
    subject { %r{\A#{Gitlab::Regex::FULL_NAMESPACE_REGEX_STR}\z} }

    it { is_expected.to match('gitlab.org') }
    it { is_expected.to match('gitlab.org/gitlab-git') }
    it { is_expected.not_to match('gitlab.org.') }
    it { is_expected.not_to match('gitlab.org/') }
    it { is_expected.not_to match('/gitlab.org') }
    it { is_expected.not_to match('gitlab.git') }
    it { is_expected.not_to match('gitlab git') }
  end
end
