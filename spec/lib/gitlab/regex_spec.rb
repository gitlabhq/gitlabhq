# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Regex do
  shared_examples_for 'project/group name regex' do
    it { is_expected.to match('gitlab-ce') }
    it { is_expected.to match('GitLab CE') }
    it { is_expected.to match('100 lines') }
    it { is_expected.to match('gitlab.git') }
    it { is_expected.to match('Český název') }
    it { is_expected.to match('Dash – is this') }
    it { is_expected.not_to match('?gitlab') }
  end

  describe '.project_name_regex' do
    subject { described_class.project_name_regex }

    it_behaves_like 'project/group name regex'
  end

  describe '.group_name_regex' do
    subject { described_class.group_name_regex }

    it_behaves_like 'project/group name regex'

    it 'allows parenthesis' do
      is_expected.to match('Group One (Test)')
    end

    it 'does not start with parenthesis' do
      is_expected.not_to match('(Invalid Group name)')
    end
  end

  describe '.project_name_regex_message' do
    subject { described_class.project_name_regex_message }

    it { is_expected.to eq("can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter, digit, emoji or '_'.") }
  end

  describe '.group_name_regex_message' do
    subject { described_class.group_name_regex_message }

    it { is_expected.to eq("can contain only letters, digits, emojis, '_', '.', dash, space, parenthesis. It must start with letter, digit, emoji or '_'.") }
  end

  describe '.environment_name_regex' do
    subject { described_class.environment_name_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('a') }
    it { is_expected.to match('foo-1') }
    it { is_expected.to match('FOO') }
    it { is_expected.to match('foo/1') }
    it { is_expected.to match('foo.1') }
    it { is_expected.not_to match('9&foo') }
    it { is_expected.not_to match('foo-^') }
    it { is_expected.not_to match('!!()()') }
    it { is_expected.not_to match('/foo') }
    it { is_expected.not_to match('foo/') }
    it { is_expected.not_to match('/foo/') }
    it { is_expected.not_to match('/') }
  end

  describe '.environment_scope_regex' do
    subject { described_class.environment_scope_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('foo*Z') }
    it { is_expected.not_to match('!!()()') }
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

  describe '.container_repository_name_regex' do
    subject { described_class.container_repository_name_regex }

    it { is_expected.to match('image') }
    it { is_expected.to match('my/image') }
    it { is_expected.to match('my/awesome/image-1') }
    it { is_expected.to match('my/awesome/image.test') }
    it { is_expected.to match('my/awesome/image--test') }
    # docker distribution allows for infinite `-`
    # https://github.com/docker/distribution/blob/master/reference/regexp.go#L13
    # but we have a range of 0,10 to add a reasonable limit.
    it { is_expected.not_to match('my/image-----------test') }
    it { is_expected.not_to match('my/image-.test') }
    it { is_expected.not_to match('.my/image') }
    it { is_expected.not_to match('my/image.') }
  end

  describe '.aws_account_id_regex' do
    subject { described_class.aws_account_id_regex }

    it { is_expected.to match('123456789012') }
    it { is_expected.not_to match('12345678901') }
    it { is_expected.not_to match('1234567890123') }
    it { is_expected.not_to match('12345678901a') }
  end

  describe '.aws_arn_regex' do
    subject { described_class.aws_arn_regex }

    it { is_expected.to match('arn:aws:iam::123456789012:role/role-name') }
    it { is_expected.to match('arn:aws:s3:::bucket/key') }
    it { is_expected.to match('arn:aws:ec2:us-east-1:123456789012:volume/vol-1') }
    it { is_expected.to match('arn:aws:rds:us-east-1:123456789012:pg:prod') }
    it { is_expected.not_to match('123456789012') }
    it { is_expected.not_to match('role/role-name') }
  end

  describe '.utc_date_regex' do
    subject { described_class.utc_date_regex }

    it { is_expected.to match('2019-10-20') }
    it { is_expected.to match('1990-01-01') }
    it { is_expected.not_to match('11-1234-90') }
    it { is_expected.not_to match('aa-1234-cc') }
    it { is_expected.not_to match('9/9/2018') }
  end

  describe '.kubernetes_namespace_regex' do
    subject { described_class.kubernetes_namespace_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('foo-bar') }
    it { is_expected.to match('1foo-bar') }
    it { is_expected.to match('foo-bar2') }
    it { is_expected.to match('foo-1bar') }
    it { is_expected.not_to match('foo.bar') }
    it { is_expected.not_to match('Foo') }
    it { is_expected.not_to match('FoO') }
    it { is_expected.not_to match('FoO-') }
    it { is_expected.not_to match('-foo-') }
    it { is_expected.not_to match('foo/bar') }
  end

  describe '.kubernetes_dns_subdomain_regex' do
    subject { described_class.kubernetes_dns_subdomain_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('foo-bar') }
    it { is_expected.to match('foo.bar') }
    it { is_expected.to match('foo1.bar') }
    it { is_expected.to match('foo1.2bar') }
    it { is_expected.to match('foo.bar1') }
    it { is_expected.to match('1foo.bar1') }
    it { is_expected.not_to match('Foo') }
    it { is_expected.not_to match('FoO') }
    it { is_expected.not_to match('FoO-') }
    it { is_expected.not_to match('-foo-') }
    it { is_expected.not_to match('foo/bar') }
  end
end
