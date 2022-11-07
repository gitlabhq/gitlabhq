# frozen_string_literal: true

RSpec.shared_context 'with purl matrix' do
  where do
    {
      'valid RubyGems package URL' => {
        url: 'pkg:gem/ruby-advisory-db-check@0.12.4',
        type: 'gem',
        namespace: nil,
        name: 'ruby-advisory-db-check',
        version: '0.12.4',
        qualifiers: nil,
        subpath: nil
      },
      'valid BitBucket package URL' => {
        url: 'pkg:bitbucket/birkenfeld/pygments-main@244fd47e07d1014f0aed9c',
        type: 'bitbucket',
        namespace: 'birkenfeld',
        name: 'pygments-main',
        version: '244fd47e07d1014f0aed9c',
        qualifiers: nil,
        subpath: nil
      },
      'valid GitHub package URL' => {
        url: 'pkg:github/package-url/purl-spec@244fd47e07d1004f0aed9c',
        type: 'github',
        namespace: 'package-url',
        name: 'purl-spec',
        version: '244fd47e07d1004f0aed9c',
        qualifiers: nil,
        subpath: nil
      },
      'valid Go module URL' => {
        url: 'pkg:golang/google.golang.org/genproto#googleapis/api/annotations',
        type: 'golang',
        namespace: 'google.golang.org',
        name: 'genproto',
        version: nil,
        qualifiers: nil,
        subpath: 'googleapis/api/annotations'
      },
      'valid Maven package URL' => {
        url: 'pkg:maven/org.apache.commons/io@1.3.4',
        type: 'maven',
        namespace: 'org.apache.commons',
        name: 'io',
        version: '1.3.4',
        qualifiers: nil,
        subpath: nil
      },
      'valid NPM package URL' => {
        url: 'pkg:npm/foobar@12.3.1',
        type: 'npm',
        namespace: nil,
        name: 'foobar',
        version: '12.3.1',
        qualifiers: nil,
        subpath: nil
      },
      'valid NuGet package URL' => {
        url: 'pkg:nuget/EnterpriseLibrary.Common@6.0.1304',
        type: 'nuget',
        namespace: nil,
        name: 'EnterpriseLibrary.Common',
        version: '6.0.1304',
        qualifiers: nil,
        subpath: nil
      },
      'valid PyPI package URL' => {
        url: 'pkg:pypi/django@1.11.1',
        type: 'pypi',
        namespace: nil,
        name: 'django',
        version: '1.11.1',
        qualifiers: nil,
        subpath: nil
      },
      'valid RPM package URL' => {
        url: 'pkg:rpm/fedora/curl@7.50.3-1.fc25?arch=i386&distro=fedora-25',
        type: 'rpm',
        namespace: 'fedora',
        name: 'curl',
        version: '7.50.3-1.fc25',
        qualifiers: { 'arch' => 'i386', 'distro' => 'fedora-25' },
        subpath: nil
      },
      'package URL with checksums' => {
        url: 'pkg:rpm/name?checksums=a,b,c',
        type: 'rpm',
        namespace: nil,
        name: 'name',
        version: nil,
        qualifiers: { 'checksums' => %w[a b c] },
        subpath: nil
      }
    }
  end
end
