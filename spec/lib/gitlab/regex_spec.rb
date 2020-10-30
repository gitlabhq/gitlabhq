# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Regex do
  shared_examples_for 'project/group name chars regex' do
    it { is_expected.to match('gitlab-ce') }
    it { is_expected.to match('GitLab CE') }
    it { is_expected.to match('100 lines') }
    it { is_expected.to match('gitlab.git') }
    it { is_expected.to match('Český název') }
    it { is_expected.to match('Dash – is this') }
  end

  shared_examples_for 'project/group name regex' do
    it_behaves_like 'project/group name chars regex'
    it { is_expected.not_to match('?gitlab') }
    it { is_expected.not_to match("Users's something") }
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

  describe '.group_name_regex_chars' do
    subject { described_class.group_name_regex_chars }

    it_behaves_like 'project/group name chars regex'

    it 'allows partial matches' do
      is_expected.to match(',Valid name wrapped in ivalid chars&')
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
    it { is_expected.to match('my/image__test') }
    # this example tests for catastrophic backtracking
    it { is_expected.to match('user1/project/a_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb------------x') }
    it { is_expected.not_to match('user1/project/a_bbbbb-------------') }
    it { is_expected.not_to match('my/image-.test') }
    it { is_expected.not_to match('my/image___test') }
    it { is_expected.not_to match('my/image_.test') }
    it { is_expected.not_to match('my/image_-test') }
    it { is_expected.not_to match('my/image..test') }
    it { is_expected.not_to match('my/image\ntest') }
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

  describe '.cluster_agent_name_regex' do
    subject { described_class.cluster_agent_name_regex }

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

  describe '.conan_package_reference_regex' do
    subject { described_class.conan_package_reference_regex }

    it { is_expected.to match('123456789') }
    it { is_expected.to match('asdf1234') }
    it { is_expected.not_to match('@foo') }
    it { is_expected.not_to match('0/pack+age/1@1/0') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.conan_revision_regex' do
    subject { described_class.conan_revision_regex }

    it { is_expected.to match('0') }
    it { is_expected.not_to match('foo') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.conan_recipe_component_regex' do
    subject { described_class.conan_recipe_component_regex }

    let(:fifty_one_characters) { 'f_a' * 17}

    it { is_expected.to match('foobar') }
    it { is_expected.to match('foo_bar') }
    it { is_expected.to match('foo+bar') }
    it { is_expected.to match('_foo+bar-baz+1.0') }
    it { is_expected.to match('1.0.0') }
    it { is_expected.not_to match('-foo_bar') }
    it { is_expected.not_to match('+foo_bar') }
    it { is_expected.not_to match('.foo_bar') }
    it { is_expected.not_to match('foo@bar') }
    it { is_expected.not_to match('foo/bar') }
    it { is_expected.not_to match('!!()()') }
    it { is_expected.not_to match(fifty_one_characters) }
  end

  describe '.package_name_regex' do
    subject { described_class.package_name_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo/bar') }
    it { is_expected.to match('@foo/bar') }
    it { is_expected.to match('com/mycompany/app/my-app') }
    it { is_expected.to match('my-package/1.0.0@my+project+path/beta') }
    it { is_expected.not_to match('my-package/1.0.0@@@@@my+project+path/beta') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('@foo/@/bar') }
    it { is_expected.not_to match('@@foo/bar') }
    it { is_expected.not_to match('my package name') }
    it { is_expected.not_to match('!!()()') }
    it { is_expected.not_to match("..\n..\foo") }
  end

  describe '.maven_file_name_regex' do
    subject { described_class.maven_file_name_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo+bar-2_0.pom') }
    it { is_expected.to match('foo.bar.baz-2.0-20190901.47283-1.jar') }
    it { is_expected.to match('maven-metadata.xml') }
    it { is_expected.to match('1.0-SNAPSHOT') }
    it { is_expected.not_to match('../../foo') }
    it { is_expected.not_to match('..\..\foo') }
    it { is_expected.not_to match('%2f%2e%2e%2f%2essh%2fauthorized_keys') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('my file name') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.maven_path_regex' do
    subject { described_class.maven_path_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo/bar') }
    it { is_expected.to match('@foo/bar') }
    it { is_expected.to match('com/mycompany/app/my-app') }
    it { is_expected.to match('com/mycompany/app/my-app/1.0-SNAPSHOT') }
    it { is_expected.to match('com/mycompany/app/my-app/1.0-SNAPSHOT+debian64') }
    it { is_expected.not_to match('com/mycompany/app/my+app/1.0-SNAPSHOT') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('@foo/@/bar') }
    it { is_expected.not_to match('my package name') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.maven_version_regex' do
    subject { described_class.maven_version_regex }

    it { is_expected.to match('0')}
    it { is_expected.to match('1') }
    it { is_expected.to match('03') }
    it { is_expected.to match('2.0') }
    it { is_expected.to match('01.2') }
    it { is_expected.to match('10.2.3-beta')}
    it { is_expected.to match('1.2-SNAPSHOT') }
    it { is_expected.to match('20') }
    it { is_expected.to match('20.3') }
    it { is_expected.to match('1.2.1') }
    it { is_expected.to match('1.4.2-12') }
    it { is_expected.to match('1.2-beta-2') }
    it { is_expected.to match('12.1.2-2-1') }
    it { is_expected.to match('1.1-beta-2') }
    it { is_expected.to match('1.3.350.v20200505-1744') }
    it { is_expected.to match('2.0.0.v200706041905-7C78EK9E_EkMNfNOd2d8qq') }
    it { is_expected.to match('1.2-alpha-1-20050205.060708-1') }
    it { is_expected.to match('703220b4e2cea9592caeb9f3013f6b1e5335c293') }
    it { is_expected.to match('RELEASE') }
    it { is_expected.not_to match('..1.2.3') }
    it { is_expected.not_to match('  1.2.3') }
    it { is_expected.not_to match("1.2.3  \r\t") }
    it { is_expected.not_to match("\r\t 1.2.3") }
    it { is_expected.not_to match('1./2.3') }
    it { is_expected.not_to match('1.2.3-4/../../') }
    it { is_expected.not_to match('1.2.3-4%2e%2e%') }
    it { is_expected.not_to match('../../../../../1.2.3') }
    it { is_expected.not_to match('%2e%2e%2f1.2.3') }
  end

  describe '.pypi_version_regex' do
    subject { described_class.pypi_version_regex }

    it { is_expected.to match('0.1') }
    it { is_expected.to match('2.0') }
    it { is_expected.to match('1.2.0')}
    it { is_expected.to match('0100!0.0') }
    it { is_expected.to match('00!1.2') }
    it { is_expected.to match('1.0a') }
    it { is_expected.to match('1.0-a') }
    it { is_expected.to match('1.0.a1') }
    it { is_expected.to match('1.0a1') }
    it { is_expected.to match('1.0-a1') }
    it { is_expected.to match('1.0alpha1') }
    it { is_expected.to match('1.0b1') }
    it { is_expected.to match('1.0beta1') }
    it { is_expected.to match('1.0rc1') }
    it { is_expected.to match('1.0pre1') }
    it { is_expected.to match('1.0preview1') }
    it { is_expected.to match('1.0.dev1') }
    it { is_expected.to match('1.0.DEV1') }
    it { is_expected.to match('1.0.post1') }
    it { is_expected.to match('1.0.rev1') }
    it { is_expected.to match('1.0.r1') }
    it { is_expected.to match('1.0c2') }
    it { is_expected.to match('2012.15') }
    it { is_expected.to match('1.0+5') }
    it { is_expected.to match('1.0+abc.5') }
    it { is_expected.to match('1!1.1') }
    it { is_expected.to match('1.0c3') }
    it { is_expected.to match('1.0rc2') }
    it { is_expected.to match('1.0c1') }
    it { is_expected.to match('1.0b2-346') }
    it { is_expected.to match('1.0b2.post345') }
    it { is_expected.to match('1.0b2.post345.dev456') }
    it { is_expected.to match('1.2.rev33+123456') }
    it { is_expected.to match('1.1.dev1') }
    it { is_expected.to match('1.0b1.dev456') }
    it { is_expected.to match('1.0a12.dev456') }
    it { is_expected.to match('1.0b2') }
    it { is_expected.to match('1.0.dev456') }
    it { is_expected.to match('1.0c1.dev456') }
    it { is_expected.to match('1.0.post456') }
    it { is_expected.to match('1.0.post456.dev34') }
    it { is_expected.to match('1.2+123abc') }
    it { is_expected.to match('1.2+abc') }
    it { is_expected.to match('1.2+abc123') }
    it { is_expected.to match('1.2+abc123def') }
    it { is_expected.to match('1.2+1234.abc') }
    it { is_expected.to match('1.2+123456') }
    it { is_expected.to match('1.2.r32+123456') }
    it { is_expected.to match('1!1.2.rev33+123456') }
    it { is_expected.to match('1.0a12') }
    it { is_expected.to match('1.2.3-45+abcdefgh') }
    it { is_expected.to match('v1.2.3') }
    it { is_expected.not_to match('1.2.3-45-abcdefgh') }
    it { is_expected.not_to match('..1.2.3') }
    it { is_expected.not_to match('  1.2.3') }
    it { is_expected.not_to match("1.2.3  \r\t") }
    it { is_expected.not_to match("\r\t 1.2.3") }
    it { is_expected.not_to match('1./2.3') }
    it { is_expected.not_to match('1.2.3-4/../../') }
    it { is_expected.not_to match('1.2.3-4%2e%2e%') }
    it { is_expected.not_to match('../../../../../1.2.3') }
    it { is_expected.not_to match('%2e%2e%2f1.2.3') }
  end

  describe '.semver_regex' do
    subject { described_class.semver_regex }

    it { is_expected.to match('1.2.3') }
    it { is_expected.to match('1.2.3-beta') }
    it { is_expected.to match('1.2.3-alpha.3') }
    it { is_expected.not_to match('1') }
    it { is_expected.not_to match('1.2') }
    it { is_expected.not_to match('1./2.3') }
    it { is_expected.not_to match('../../../../../1.2.3') }
    it { is_expected.not_to match('%2e%2e%2f1.2.3') }
  end

  describe '.go_package_regex' do
    subject { described_class.go_package_regex }

    it { is_expected.to match('example.com') }
    it { is_expected.to match('example.com/foo') }
    it { is_expected.to match('example.com/foo/bar') }
    it { is_expected.to match('example.com/foo/bar/baz') }
    it { is_expected.to match('tl.dr.foo.bar.baz') }
  end

  describe '.unbounded_semver_regex' do
    subject { described_class.unbounded_semver_regex }

    it { is_expected.to match('1.2.3') }
    it { is_expected.to match('1.2.3-beta') }
    it { is_expected.to match('1.2.3-alpha.3') }
    it { is_expected.not_to match('1') }
    it { is_expected.not_to match('1.2') }
    it { is_expected.not_to match('1./2.3') }
  end

  describe '.generic_package_version_regex' do
    subject { described_class.generic_package_version_regex }

    it { is_expected.to match('1.2.3') }
    it { is_expected.to match('1.3.350') }
    it { is_expected.not_to match('1.3.350-20201230123456') }
    it { is_expected.not_to match('..1.2.3') }
    it { is_expected.not_to match('  1.2.3') }
    it { is_expected.not_to match("1.2.3  \r\t") }
    it { is_expected.not_to match("\r\t 1.2.3") }
    it { is_expected.not_to match('1.2.3-4/../../') }
    it { is_expected.not_to match('1.2.3-4%2e%2e%') }
    it { is_expected.not_to match('../../../../../1.2.3') }
    it { is_expected.not_to match('%2e%2e%2f1.2.3') }
    it { is_expected.not_to match('') }
  end
end
