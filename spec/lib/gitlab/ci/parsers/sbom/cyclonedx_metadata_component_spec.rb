# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::CyclonedxMetadataComponent, feature_category: :dependency_management do
  describe "#parse" do
    let_it_be(:name) { 'Root Application' }
    let_it_be(:type) { 'application' }
    let_it_be(:ref) { 'bom-ref' }

    subject(:component) { described_class.new(data).parse }

    %w[name type bom-ref].each do |property|
      context "without #{property}" do
        let_it_be(:data) { { 'name' => name, 'type' => type, 'bom-ref' => ref }.delete(property.to_sym) }

        it 'returns nil' do
          expect(component).to be_nil
        end
      end
    end

    context 'with all required properties' do
      let_it_be(:data) { { 'name' => name, 'type' => type, 'bom-ref' => ref } }

      it 'returns a sbom component' do
        expect(component).to be_kind_of(::Gitlab::Ci::Reports::Sbom::Component)

        expect(component.component_type).to eq(type)
        expect(component.name).to eq(name)
        expect(component.ref).to eq(ref)
      end
    end
  end
end
