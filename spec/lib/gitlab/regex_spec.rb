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

  describe '.build_trace_section_regex' do
    subject { described_class.build_trace_section_regex }

    context 'without options' do
      example = "section_start:1600445393032:NAME\r\033\[0K"

      it { is_expected.to match(example) }
      it { is_expected.to match("section_end:12345678:aBcDeFg1234\r\033\[0K") }
      it { is_expected.to match("section_start:0:sect_for_alpha-v1.0\r\033\[0K") }
      it { is_expected.not_to match("section_start:section:0\r\033\[0K") }
      it { is_expected.not_to match("section_:1600445393032:NAME\r\033\[0K") }
      it { is_expected.not_to match(example.upcase) }
    end

    context 'with options' do
      it { is_expected.to match("section_start:1600445393032:NAME[collapsed=true]\r\033\[0K") }
      it { is_expected.to match("section_start:1600445393032:NAME[collapsed=true, example_option=false]\r\033\[0K") }
      it { is_expected.to match("section_start:1600445393032:NAME[collapsed=true,example_option=false]\r\033\[0K") }
      it { is_expected.to match("section_start:1600445393032:NAME[numeric_option=1234567]\r\033\[0K") }
      # Without splitting the regex in one for start and one for end,
      # this is possible, however, it is ignored for section_end.
      it { is_expected.to match("section_end:1600445393032:NAME[collapsed=true]\r\033\[0K") }
      it { is_expected.not_to match("section_start:1600445393032:NAME[collapsed=[]]]\r\033\[0K") }
      it { is_expected.not_to match("section_start:1600445393032:NAME[collapsed = true]\r\033\[0K") }
      it { is_expected.not_to match("section_start:1600445393032:NAME[collapsed = true, example_option=false]\r\033\[0K") }
      it { is_expected.not_to match("section_start:1600445393032:NAME[collapsed=true,  example_option=false]\r\033\[0K") }
      it { is_expected.not_to match("section_start:1600445393032:NAME[]\r\033\[0K") }
    end
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

  describe '.composer_dev_version_regex' do
    subject { described_class.composer_dev_version_regex }

    it { is_expected.to match('dev-master') }
    it { is_expected.to match('1.x-dev') }
    it { is_expected.not_to match('foobar') }
    it { is_expected.not_to match('1.2.3') }
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

    it 'has no backtracking issue' do
      Timeout.timeout(1) do
        expect(subject).not_to match("-" * 50000 + ";")
      end
    end
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

  describe '.npm_package_name_regex' do
    subject { described_class.npm_package_name_regex }

    it { is_expected.to match('@scope/package') }
    it { is_expected.to match('unscoped-package') }
    it { is_expected.not_to match('@first-scope@second-scope/package') }
    it { is_expected.not_to match('scope-without-at-symbol/package') }
    it { is_expected.not_to match('@not-a-scoped-package') }
    it { is_expected.not_to match('@scope/sub/package') }
    it { is_expected.not_to match('@scope/../../package') }
    it { is_expected.not_to match('@scope%2e%2e%2fpackage') }
    it { is_expected.not_to match('@%2e%2e%2f/package') }

    context 'capturing group' do
      [
        ['@scope/package', 'scope'],
        ['unscoped-package', nil],
        ['@not-a-scoped-package', nil],
        ['@scope/sub/package', nil],
        ['@inv@lid-scope/package', nil]
      ].each do |package_name, extracted_scope_name|
        it "extracts the scope name for #{package_name}" do
          match = package_name.match(described_class.npm_package_name_regex)
          expect(match&.captures&.first).to eq(extracted_scope_name)
        end
      end
    end
  end

  describe '.nuget_version_regex' do
    subject { described_class.nuget_version_regex }

    it { is_expected.to match('1.2.3') }
    it { is_expected.to match('1.2.3.4') }
    it { is_expected.to match('1.2.3.4-stable.1') }
    it { is_expected.to match('1.2.3-beta') }
    it { is_expected.to match('1.2.3-alpha.3') }
    it { is_expected.to match('1.0.7+r3456') }
    it { is_expected.not_to match('1') }
    it { is_expected.not_to match('1.2') }
    it { is_expected.not_to match('1./2.3') }
    it { is_expected.not_to match('../../../../../1.2.3') }
    it { is_expected.not_to match('%2e%2e%2f1.2.3') }
  end

  describe '.nuget_package_name_regex' do
    subject { described_class.nuget_package_name_regex }

    it { is_expected.to match('My.Package') }
    it { is_expected.to match('My.Package.Mvc') }
    it { is_expected.to match('MyPackage') }
    it { is_expected.to match('My.23.Package') }
    it { is_expected.to match('My23Package') }
    it { is_expected.to match('runtime.my-test64.runtime.package.Mvc') }
    it { is_expected.to match('my_package') }
    it { is_expected.not_to match('My/package') }
    it { is_expected.not_to match('../../../my_package') }
    it { is_expected.not_to match('%2e%2e%2fmy_package') }
  end

  describe '.terraform_module_package_name_regex' do
    subject { described_class.terraform_module_package_name_regex }

    it { is_expected.to match('my-module/my-system') }
    it { is_expected.to match('my/module') }
    it { is_expected.not_to match('my-module') }
    it { is_expected.not_to match('My-Module') }
    it { is_expected.not_to match('my_module') }
    it { is_expected.not_to match('my.module') }
    it { is_expected.not_to match('../../../my-module') }
    it { is_expected.not_to match('%2e%2e%2fmy-module') }
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

  describe '.debian_package_name_regex' do
    subject { described_class.debian_package_name_regex }

    it { is_expected.to match('0ad') }
    it { is_expected.to match('g++') }
    it { is_expected.to match('lua5.1') }
    it { is_expected.to match('samba') }

    # may not be empty string
    it { is_expected.not_to match('') }
    # must start with an alphanumeric character
    it { is_expected.not_to match('-a') }
    it { is_expected.not_to match('+a') }
    it { is_expected.not_to match('.a') }
    it { is_expected.not_to match('_a') }
    # only letters, digits and characters '-+._'
    it { is_expected.not_to match('a~') }
    it { is_expected.not_to match('aé') }

    # More strict Lintian regex
    # at least 2 chars
    it { is_expected.not_to match('a') }
    # lowercase only
    it { is_expected.not_to match('Aa') }
    it { is_expected.not_to match('aA') }
    # No underscore
    it { is_expected.not_to match('a_b') }
  end

  describe '.debian_version_regex' do
    subject { described_class.debian_version_regex }

    context 'valid versions' do
      it { is_expected.to match('1.0') }
      it { is_expected.to match('1.0~alpha1') }
      it { is_expected.to match('2:4.9.5+dfsg-5+deb10u1') }
    end

    context 'dpkg errors' do
      # version string is empty
      it { is_expected.not_to match('') }
      # version string has embedded spaces
      it { is_expected.not_to match('1 0') }
      # epoch in version is empty
      it { is_expected.not_to match(':1.0') }
      # epoch in version is not number
      it { is_expected.not_to match('a:1.0') }
      # epoch in version is negative
      it { is_expected.not_to match('-1:1.0') }
      # epoch in version is too big
      it { is_expected.not_to match('9999999999:1.0') }
      # nothing after colon in version number
      it { is_expected.not_to match('2:') }
      # revision number is empty
      # Note: we are less strict here
      # it { is_expected.not_to match('1.0-') }
      # version number is empty
      it { is_expected.not_to match('-1') }
      it { is_expected.not_to match('2:-1') }
    end

    context 'dpkg warnings' do
      # version number does not start with digit
      it { is_expected.not_to match('a') }
      it { is_expected.not_to match('a1.0') }
      # invalid character in version number
      it { is_expected.not_to match('1_0') }
      # invalid character in revision number
      it { is_expected.not_to match('1.0-1_0') }
    end

    context 'dpkg accepts' do
      # dpkg accepts leading or trailing space
      it { is_expected.not_to match(' 1.0') }
      it { is_expected.not_to match('1.0 ') }
      # dpkg accepts multiple colons
      it { is_expected.not_to match('1:2:3') }
    end
  end

  describe '.debian_architecture_regex' do
    subject { described_class.debian_architecture_regex }

    it { is_expected.to match('amd64') }
    it { is_expected.to match('kfreebsd-i386') }

    # may not be empty string
    it { is_expected.not_to match('') }
    # must start with an alphanumeric
    it { is_expected.not_to match('-a') }
    it { is_expected.not_to match('+a') }
    it { is_expected.not_to match('.a') }
    it { is_expected.not_to match('_a') }
    # only letters, digits and characters '-'
    it { is_expected.not_to match('a+b') }
    it { is_expected.not_to match('a.b') }
    it { is_expected.not_to match('a_b') }
    it { is_expected.not_to match('a~') }
    it { is_expected.not_to match('aé') }

    # More strict
    # Enforce lowercase
    it { is_expected.not_to match('AMD64') }
    it { is_expected.not_to match('Amd64') }
    it { is_expected.not_to match('aMD64') }
  end

  describe '.debian_distribution_regex' do
    subject { described_class.debian_distribution_regex }

    it { is_expected.to match('buster') }
    it { is_expected.to match('buster-updates') }
    it { is_expected.to match('Debian10.5') }

    # Do not allow slash, even if this exists in the wild
    it { is_expected.not_to match('jessie/updates') }

    # Do not allow Unicode
    it { is_expected.not_to match('hé') }
  end

  describe '.debian_component_regex' do
    subject { described_class.debian_component_regex }

    it { is_expected.to match('main') }
    it { is_expected.to match('non-free') }

    # Do not allow slash
    it { is_expected.not_to match('non/free') }

    # Do not allow Unicode
    it { is_expected.not_to match('hé') }
  end

  describe '.helm_channel_regex' do
    subject { described_class.helm_channel_regex }

    it { is_expected.to match('release') }
    it { is_expected.to match('my-repo') }
    it { is_expected.to match('my-repo42') }

    # Do not allow empty
    it { is_expected.not_to match('') }

    # Do not allow Unicode
    it { is_expected.not_to match('hé') }
  end

  describe '.helm_package_regex' do
    subject { described_class.helm_package_regex }

    it { is_expected.to match('release') }
    it { is_expected.to match('my-repo') }
    it { is_expected.to match('my-repo42') }

    # Do not allow empty
    it { is_expected.not_to match('') }

    # Do not allow Unicode
    it { is_expected.not_to match('hé') }

    it { is_expected.not_to match('my/../repo') }
    it { is_expected.not_to match('me%2f%2e%2e%2f') }
  end

  describe '.helm_version_regex' do
    subject { described_class.helm_version_regex }

    it { is_expected.to match('1.2.3') }
    it { is_expected.to match('1.2.3-beta') }
    it { is_expected.to match('1.2.3-alpha.3') }

    it { is_expected.to match('v1.2.3') }
    it { is_expected.to match('v1.2.3-beta') }
    it { is_expected.to match('v1.2.3-alpha.3') }

    it { is_expected.not_to match('1') }
    it { is_expected.not_to match('1.2') }
    it { is_expected.not_to match('1./2.3') }
    it { is_expected.not_to match('../../../../../1.2.3') }
    it { is_expected.not_to match('%2e%2e%2f1.2.3') }

    it { is_expected.not_to match('v1') }
    it { is_expected.not_to match('v1.2') }
    it { is_expected.not_to match('v1./2.3') }
    it { is_expected.not_to match('v../../../../../1.2.3') }
    it { is_expected.not_to match('v%2e%2e%2f1.2.3') }
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
    it { is_expected.to match('1.3.350-20201230123456') }
    it { is_expected.to match('1.2.3-rc1') }
    it { is_expected.to match('1.2.3g') }
    it { is_expected.to match('1.2') }
    it { is_expected.to match('1.2.bananas') }
    it { is_expected.to match('v1.2.4-build') }
    it { is_expected.to match('d50d836eb3de6177ce6c7a5482f27f9c2c84b672') }
    it { is_expected.to match('this_is_a_string_only') }
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

  describe '.generic_package_name_regex' do
    subject { described_class.generic_package_name_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo.bar.baz-2.0-20190901.47283-1') }
    it { is_expected.not_to match('../../foo') }
    it { is_expected.not_to match('..\..\foo') }
    it { is_expected.not_to match('%2f%2e%2e%2f%2essh%2fauthorized_keys') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('my file name') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.generic_package_file_name_regex' do
    subject { described_class.generic_package_file_name_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo.bar.baz-2.0-20190901.47283-1.jar') }
    it { is_expected.not_to match('../../foo') }
    it { is_expected.not_to match('..\..\foo') }
    it { is_expected.not_to match('%2f%2e%2e%2f%2essh%2fauthorized_keys') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('my file name') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.prefixed_semver_regex' do
    subject { described_class.prefixed_semver_regex }

    it { is_expected.to match('v1.2.3') }
    it { is_expected.to match('v1.2.3-beta') }
    it { is_expected.to match('v1.2.3-alpha.3') }
    it { is_expected.not_to match('v1') }
    it { is_expected.not_to match('v1.2') }
    it { is_expected.not_to match('v1./2.3') }
    it { is_expected.not_to match('v../../../../../1.2.3') }
    it { is_expected.not_to match('v%2e%2e%2f1.2.3') }
  end

  describe 'Packages::API_PATH_REGEX' do
    subject { described_class::Packages::API_PATH_REGEX }

    it { is_expected.to match('/api/v4/group/12345/-/packages/composer/p/123456789') }
    it { is_expected.to match('/api/v4/group/12345/-/packages/composer/p2/pkg_name') }
    it { is_expected.to match('/api/v4/group/12345/-/packages/composer/packages') }
    it { is_expected.to match('/api/v4/group/12345/-/packages/composer/pkg_name') }
    it { is_expected.to match('/api/v4/groups/1234/-/packages/maven/a/path/file.jar') }
    it { is_expected.to match('/api/v4/groups/1234/-/packages/nuget/index') }
    it { is_expected.to match('/api/v4/groups/1234/-/packages/nuget/metadata/pkg_name/1.3.4') }
    it { is_expected.to match('/api/v4/groups/1234/-/packages/nuget/metadata/pkg_name/index') }
    it { is_expected.to match('/api/v4/groups/1234/-/packages/nuget/query') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/digest') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/download_urls') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref/digest') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref/download_urls') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref/upload_urls') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/upload_urls') }
    it { is_expected.to match('/api/v4/packages/conan/v1/conans/search') }
    it { is_expected.to match('/api/v4/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/export/file.name') }
    it { is_expected.to match('/api/v4/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/export/file.name/authorize') }
    it { is_expected.to match('/api/v4/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/package/pkg_ref/pkg_revision/file.name') }
    it { is_expected.to match('/api/v4/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/package/pkg_ref/pkg_revision/file.name/authorize') }
    it { is_expected.to match('/api/v4/packages/conan/v1/ping') }
    it { is_expected.to match('/api/v4/packages/conan/v1/users/authenticate') }
    it { is_expected.to match('/api/v4/packages/conan/v1/users/check_credentials') }
    it { is_expected.to match('/api/v4/packages/maven/a/path/file.jar') }
    it { is_expected.to match('/api/v4/packages/npm/-/package/pkg_name/dist-tags') }
    it { is_expected.to match('/api/v4/packages/npm/-/package/pkg_name/dist-tags/tag') }
    it { is_expected.to match('/api/v4/packages/npm/pkg_name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/composer') }
    it { is_expected.to match('/api/v4/projects/1234/packages/composer/archives/pkg_name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/digest') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/download_urls') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref/digest') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref/download_urls') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/packages/pkg_ref/upload_urls') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/pkg_name/1.2.3/username/stable/upload_urls') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/conans/search') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/export/file.name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/export/file.name/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/package/pkg_ref/pkg_revision/file.name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/files/pkg_name/1.2.3/username/stable/2.3/package/pkg_ref/pkg_revision/file.name/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/ping') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/users/authenticate') }
    it { is_expected.to match('/api/v4/projects/1234/packages/conan/v1/users/check_credentials') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/dists/stable/compon/binary-x64/Packages') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/dists/stable/InRelease') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/dists/stable/Release') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/dists/stable/Release.gpg') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/file.name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/file.name/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/debian/pool/compon/e/pkg/file.name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/generic/pkg_name/1.3.4/myfile.txt') }
    it { is_expected.to match('/api/v4/projects/1234/packages/generic/pkg_name/1.3.4/myfile.txt/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/go/my_module/@v/11.2.3.info') }
    it { is_expected.to match('/api/v4/projects/1234/packages/go/my_module/@v/11.2.3.mod') }
    it { is_expected.to match('/api/v4/projects/1234/packages/go/my_module/@v/11.2.3.zip') }
    it { is_expected.to match('/api/v4/projects/1234/packages/go/my_module/@v/list') }
    it { is_expected.to match('/api/v4/projects/1234/packages/maven/a/path/file.jar') }
    it { is_expected.to match('/api/v4/projects/1234/packages/maven/a/path/file.jar/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/npm/-/package/pkg_name/dist-tags') }
    it { is_expected.to match('/api/v4/projects/1234/packages/npm/-/package/pkg_name/dist-tags/tag') }
    it { is_expected.to match('/api/v4/projects/1234/packages/npm/pkg_name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/npm/pkg_name/-/tarball.tgz') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/download/pkg_name/1.3.4/pkg.npkg') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/download/pkg_name/index') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/index') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/metadata/pkg_name/1.3.4') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/metadata/pkg_name/index') }
    it { is_expected.to match('/api/v4/projects/1234/packages/nuget/query') }
    it { is_expected.to match('/api/v4/projects/1234/packages/pypi') }
    it { is_expected.to match('/api/v4/projects/1234/packages/pypi/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/pypi/files/1234567890/file.identifier') }
    it { is_expected.to match('/api/v4/projects/1234/packages/pypi/simple/pkg_name') }
    it { is_expected.to match('/api/v4/projects/1234/packages/rubygems/api/v1/dependencies') }
    it { is_expected.to match('/api/v4/projects/1234/packages/rubygems/api/v1/gems') }
    it { is_expected.to match('/api/v4/projects/1234/packages/rubygems/api/v1/gems/authorize') }
    it { is_expected.to match('/api/v4/projects/1234/packages/rubygems/gems/pkg') }
    it { is_expected.to match('/api/v4/projects/1234/packages/rubygems/pkg') }
    it { is_expected.to match('/api/v4/projects/1234/packages/rubygems/quick/Marshal.4.8/pkg') }
    it { is_expected.not_to match('') }
    it { is_expected.not_to match('foo') }
    it { is_expected.not_to match('/api/v4') }
    it { is_expected.not_to match('/api/v4/version') }
    it { is_expected.not_to match('/api/v4/packages') }
    it { is_expected.not_to match('/api/v4/packages/') }
    it { is_expected.not_to match('/api/v4/group') }
    it { is_expected.not_to match('/api/v4/group/12345') }
    it { is_expected.not_to match('/api/v4/group/12345/-') }
    it { is_expected.not_to match('/api/v4/group/12345/-/packages') }
    it { is_expected.not_to match('/api/v4/group/12345/-/packages/') }
    it { is_expected.not_to match('/api/v4/group/12345/-/packages/50') }
    it { is_expected.not_to match('/api/v4/groups') }
    it { is_expected.not_to match('/api/v4/groups/12345') }
    it { is_expected.not_to match('/api/v4/groups/12345/-') }
    it { is_expected.not_to match('/api/v4/groups/12345/-/packages') }
    it { is_expected.not_to match('/api/v4/groups/12345/-/packages/') }
    it { is_expected.not_to match('/api/v4/groups/12345/-/packages/50') }
    it { is_expected.not_to match('/api/v4/groups/12345/packages') }
    it { is_expected.not_to match('/api/v4/groups/12345/packages/') }
    it { is_expected.not_to match('/api/v4/groups/12345/badges') }
    it { is_expected.not_to match('/api/v4/groups/12345/issues') }
    it { is_expected.not_to match('/api/v4/projects') }
    it { is_expected.not_to match('/api/v4/projects/1234') }
    it { is_expected.not_to match('/api/v4/projects/1234/packages') }
    it { is_expected.not_to match('/api/v4/projects/1234/packages/') }
    it { is_expected.not_to match('/api/v4/projects/1234/packages/50') }
    it { is_expected.not_to match('/api/v4/projects/1234/packages/50/package_files') }
    it { is_expected.not_to match('/api/v4/projects/1234/merge_requests') }
    it { is_expected.not_to match('/api/v4/projects/1234/registry/repositories') }
    it { is_expected.not_to match('/api/v4/projects/1234/issues') }
    it { is_expected.not_to match('/api/v4/projects/1234/members') }
    it { is_expected.not_to match('/api/v4/projects/1234/milestones') }

    # Group level Debian API endpoints are not matched as it's not using the correct prefix (groups/:id/-/packages/)
    # TODO: Update Debian group level endpoints urls and adjust this specs: https://gitlab.com/gitlab-org/gitlab/-/issues/326805
    it { is_expected.not_to match('/api/v4/groups/1234/packages/debian/dists/stable/compon/binary-compo/Packages') }
    it { is_expected.not_to match('/api/v4/groups/1234/packages/debian/dists/stable/InRelease') }
    it { is_expected.not_to match('/api/v4/groups/1234/packages/debian/dists/stable/Release') }
    it { is_expected.not_to match('/api/v4/groups/1234/packages/debian/dists/stable/Release.gpg') }
    it { is_expected.not_to match('/api/v4/groups/1234/packages/debian/pool/compon/a/pkg/file.name') }
  end
end
