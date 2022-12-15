# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Component, feature_category: :dependency_management do
  let(:component_type) { 'library' }
  let(:name) { 'component-name' }
  let(:purl_type) { 'npm' }
  let(:purl) { Sbom::PackageUrl.new(type: purl_type, name: name, version: version).to_s }
  let(:version) { 'v0.0.1' }

  subject(:component) do
    described_class.new(
      type: component_type,
      name: name,
      purl: purl,
      version: version
    )
  end

  it 'has correct attributes' do
    expect(component).to have_attributes(
      component_type: component_type,
      name: name,
      purl: an_object_having_attributes(type: purl_type),
      version: version
    )
  end

  describe '#ingestible?' do
    subject { component.ingestible? }

    context 'when component_type is invalid' do
      let(:component_type) { 'invalid' }

      it { is_expected.to be(false) }
    end

    context 'when purl_type is invalid' do
      let(:purl_type) { 'invalid' }

      it { is_expected.to be(false) }
    end

    context 'when component_type is valid' do
      where(:component_type) { ::Enums::Sbom.component_types.keys.map(&:to_s) }

      with_them do
        it { is_expected.to be(true) }
      end
    end

    context 'when purl_type is valid' do
      where(:purl_type) { ::Enums::Sbom.purl_types.keys.map(&:to_s) }

      with_them do
        it { is_expected.to be(true) }
      end
    end

    context 'when there is no purl' do
      let(:purl) { nil }

      it { is_expected.to be(true) }
    end
  end
end
