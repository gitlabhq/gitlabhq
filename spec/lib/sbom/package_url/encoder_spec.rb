# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../support/shared_contexts/lib/sbom/package_url_shared_contexts'

RSpec.describe Sbom::PackageUrl::Encoder, feature_category: :dependency_management do
  describe '#encode' do
    let(:package) do
      ::Sbom::PackageUrl.new(
        type: type,
        namespace: namespace,
        name: name,
        version: version,
        qualifiers: qualifiers,
        subpath: subpath
      )
    end

    subject(:encode) { described_class.new(package).encode }

    include_context 'with valid purl examples'

    with_them do
      it { is_expected.to eq(canonical_purl) }
    end

    context 'when purl requires normalization' do
      let(:package) do
        ::Sbom::PackageUrl.new(
          type: 'github',
          namespace: 'GitLab-Org',
          name: 'GitLab',
          version: '1.0.0'
        )
      end

      it 'outputs normalized form' do
        expect(encode).to eq('pkg:github/gitlab-org/gitlab@1.0.0')
      end
    end
  end
end
