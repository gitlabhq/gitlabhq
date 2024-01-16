# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::Source::Trivy, feature_category: :dependency_management do
  subject { described_class.source(property_data) }

  context 'when all property data is present' do
    let(:property_data) do
      {
        'PkgID' => 'sha256:47ce8fad8..',
        'LayerDigest' => 'registry.test.com/atiwari71/container-scanning-test/main@sha256:e14a4bcf..',
        'LayerDiffID' => 'sha256:94dd7d531fa..',
        'SrcEpoch' => 'sha256:5d20c808c..'
      }
    end

    it 'returns expected source data' do
      is_expected.to have_attributes(
        source_type: :trivy,
        data: property_data
      )
    end
  end
end
