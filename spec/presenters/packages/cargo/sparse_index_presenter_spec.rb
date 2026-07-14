# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::SparseIndexPresenter, feature_category: :package_registry do
  let(:metadatum_v1) { build_stubbed(:cargo_metadatum) }
  let(:metadatum_v2) { build_stubbed(:cargo_metadatum) }

  let(:metadata) { [metadatum_v2, metadatum_v1] }

  subject(:body) { described_class.new(metadata).body }

  describe '#body' do
    it 'returns newline-delimited JSON, one line per metadatum, preserving order' do
      lines = body.split("\n")

      expect(lines.size).to eq(2)
      expect(lines.map { |line| Gitlab::Json.safe_parse(line) })
        .to eq([metadatum_v2.index_content, metadatum_v1.index_content])
    end

    context 'when there is no metadata' do
      let(:metadata) { [] }

      it { is_expected.to eq('') }
    end
  end
end
