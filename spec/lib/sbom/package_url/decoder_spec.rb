# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../support/shared_contexts/lib/sbom/package_url_shared_contexts'

RSpec.describe Sbom::PackageUrl::Decoder, feature_category: :dependency_management do
  describe '#decode' do
    subject(:decode) { described_class.new(purl).decode! }

    include_context 'with valid purl examples'

    with_them do
      it do
        is_expected.to have_attributes(
          type: type,
          namespace: namespace,
          name: name,
          version: version,
          qualifiers: qualifiers,
          subpath: subpath
        )
      end
    end

    context 'when no argument is passed' do
      let(:purl) { nil }

      it 'raises an error' do
        expect { decode }.to raise_error(ArgumentError)
      end
    end

    context 'when an invalid package URL string is passed' do
      include_context 'with invalid purl examples'

      with_them do
        it 'raises an error' do
          expect { decode }.to raise_error(Sbom::PackageUrl::InvalidPackageUrl)
        end
      end
    end

    context 'when namespace or subpath contains an encoded slash' do
      where(:purl) do
        [
          'pkg:golang/google.org/golang/genproto#googleapis%2fapi%2fannotations',
          'pkg:golang/google.org%2fgolang/genproto#googleapis/api/annotations'
        ]
      end

      with_them do
        it { expect { decode }.to raise_error(Sbom::PackageUrl::InvalidPackageUrl) }
      end
    end

    context 'when name contains an encoded slash' do
      let(:purl) { 'pkg:golang/google.org/golang%2fgenproto#googleapis/api/annotations' }

      it do
        is_expected.to have_attributes(
          type: 'golang',
          namespace: 'google.org',
          name: 'golang/genproto',
          version: nil,
          qualifiers: nil,
          subpath: 'googleapis/api/annotations'
        )
      end
    end

    context 'with URL encoded segments' do
      let(:purl) do
        'pkg:golang/namespace%21/google.golang.org%20genproto@version%21?k=v%21#googleapis%20api%20annotations'
      end

      it 'decodes them' do
        is_expected.to have_attributes(
          type: 'golang',
          namespace: 'namespace!',
          name: 'google.golang.org genproto',
          version: 'version!',
          qualifiers: { 'k' => 'v!' },
          subpath: 'googleapis api annotations'
        )
      end
    end

    context 'when segments contain empty values' do
      let(:purl) { 'pkg:golang/google.golang.org//.././genproto#googleapis/..//./api/annotations' }

      it 'removes them from the segments' do
        is_expected.to have_attributes(
          type: 'golang',
          namespace: 'google.golang.org/../.', # . and .. are allowed in the namespace, but not the subpath
          name: 'genproto',
          version: nil,
          qualifiers: nil,
          subpath: 'googleapis/api/annotations'
        )
      end
    end

    context 'when qualifiers have no value' do
      let(:purl) { 'pkg:rpm/fedora/curl@7.50.3-1.fc25?arch=i386&distro=fedora-25&foo=&bar=' }

      it 'they are ignored' do
        is_expected.to have_attributes(
          type: 'rpm',
          namespace: 'fedora',
          name: 'curl',
          version: '7.50.3-1.fc25',
          qualifiers: { 'arch' => 'i386',
                        'distro' => 'fedora-25' },
          subpath: nil
        )
      end
    end
  end
end
