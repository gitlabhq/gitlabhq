# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ParseDebian822Service do
  subject { described_class.new(input) }

  context 'with dpkg-deb --field output' do
    let(:input) do
      <<~HEREDOC
        Package: libsample0
        Source: sample
        Version: 1.2.3~alpha2
        Architecture: amd64
        Maintainer: John Doe <john.doe@example.com>
        Installed-Size: 9
        Section: libs
        Priority: optional
        Multi-Arch: same
        Homepage: https://gitlab.com/
        Description: Some mostly empty lib
         Used in GitLab tests.
         .
         Testing another paragraph.
      HEREDOC
    end

    it 'return as expected, preserving order' do
      expected = {
        'Package: libsample0' => {
          'Package' => 'libsample0',
          'Source' => 'sample',
          'Version' => '1.2.3~alpha2',
          'Architecture' => 'amd64',
          'Maintainer' => 'John Doe <john.doe@example.com>',
          'Installed-Size' => '9',
          'Section' => 'libs',
          'Priority' => 'optional',
          'Multi-Arch' => 'same',
          'Homepage' => 'https://gitlab.com/',
          'Description' => "Some mostly empty lib\nUsed in GitLab tests.\n\nTesting another paragraph."
        }
      }

      expect(subject.execute.to_s).to eq(expected.to_s)
    end
  end

  context 'with control file' do
    let(:input) { fixture_file('packages/debian/sample/debian/control') }

    it 'return as expected, preserving order' do
      expected = {
        'Source: sample' => {
          'Source' => 'sample',
          'Priority' => 'optional',
          'Maintainer' => 'John Doe <john.doe@example.com>',
          'Build-Depends' => 'debhelper-compat (= 13)',
          'Standards-Version' => '4.5.0',
          'Section' => 'libs',
          'Homepage' => 'https://gitlab.com/',
          # 'Vcs-Browser' => 'https://salsa.debian.org/debian/sample-1.2.3',
          # '#Vcs-Git' => 'https://salsa.debian.org/debian/sample-1.2.3.git',
          'Rules-Requires-Root' => 'no'
        },
        'Package: sample-dev' => {
          'Package' => 'sample-dev',
          'Section' => 'libdevel',
          'Architecture' => 'any',
          'Multi-Arch' => 'same',
          'Depends' => 'libsample0 (= ${binary:Version}), ${misc:Depends}',
          'Description' => "Some mostly empty development files\nUsed in GitLab tests.\n\nTesting another paragraph."
        },
        'Package: libsample0' => {
          'Package' => 'libsample0',
          'Architecture' => 'any',
          'Multi-Arch' => 'same',
          'Depends' => '${shlibs:Depends}, ${misc:Depends}',
          'Description' => "Some mostly empty lib\nUsed in GitLab tests.\n\nTesting another paragraph."
         },
         'Package: sample-udeb' => {
           'Package' => 'sample-udeb',
           'Package-Type' => 'udeb',
           'Architecture' => 'any',
           'Depends' => 'installed-base',
           'Description' => 'Some mostly empty udeb'
         }
      }

      expect(subject.execute.to_s).to eq(expected.to_s)
    end
  end

  context 'with empty input' do
    let(:input) { '' }

    it 'return a empty hash' do
      expect(subject.execute).to eq({})
    end
  end

  context 'with unexpected continuation line' do
    let(:input) { ' continuation' }

    it 'raise error' do
      expect {subject.execute}.to raise_error(described_class::InvalidDebian822Error, 'Parse error. Unexpected continuation line')
    end
  end

  context 'with duplicate field' do
    let(:input) do
      <<~HEREDOC
        Package: libsample0
        Source: sample
        Source: sample
      HEREDOC
    end

    it 'raise error' do
      expect {subject.execute}.to raise_error(described_class::InvalidDebian822Error, "Duplicate field 'Source' in section 'Package: libsample0'")
    end
  end

  context 'with incorrect input' do
    let(:input) do
      <<~HEREDOC
        Hello
      HEREDOC
    end

    it 'raise error' do
      expect {subject.execute}.to raise_error(described_class::InvalidDebian822Error, 'Parse error on line Hello')
    end
  end

  context 'with duplicate section' do
    let(:input) do
      <<~HEREDOC
        Package: libsample0

        Package: libsample0
      HEREDOC
    end

    it 'raise error' do
      expect {subject.execute}.to raise_error(described_class::InvalidDebian822Error, "Duplicate section 'Package: libsample0'")
    end
  end
end
