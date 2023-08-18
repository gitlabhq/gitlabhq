# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::V2::MetadataIndexPresenter, feature_category: :package_registry do
  describe '#xml' do
    let(:presenter) { described_class.new }

    subject(:xml) { Nokogiri::XML(presenter.xml.to_xml) }

    specify { expect(xml.root.name).to eq('Edmx') }

    specify { expect(xml.at_xpath('//edmx:Edmx')).to be_present }

    specify { expect(xml.at_xpath('//edmx:Edmx/edmx:DataServices')).to be_present }

    specify do
      expect(xml.css('*').map(&:name)).to include(
        'Schema', 'EntityType', 'Key', 'PropertyRef', 'EntityContainer', 'EntitySet', 'FunctionImport', 'Parameter'
      )
    end

    specify do
      expect(xml.css('*').select { |el| el.name == 'Property' }.map { |el| el.attribute_nodes.first.value })
        .to match_array(
          %w[Id Version Authors Dependencies Description DownloadCount IconUrl Published ProjectUrl Tags Title
            LicenseUrl]
        )
    end

    specify { expect(xml.css('*').detect { |el| el.name == 'EntityContainer' }.attr('Name')).to eq('V2FeedContext') }

    specify { expect(xml.css('*').detect { |el| el.name == 'FunctionImport' }.attr('Name')).to eq('FindPackagesById') }
  end
end
