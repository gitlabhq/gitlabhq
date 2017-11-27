require 'rake_helper'

describe 'geo rake tasks' do
  before do
    Rake.application.rake_require 'tasks/geo'
  end

  describe 'set_primary_node task' do
    before do
      expect(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      stub_config_setting(protocol: 'https')
    end

    it 'creates a GeoNode' do
      expect(GeoNode.count).to eq(0)

      run_rake_task('geo:set_primary_node')

      expect(GeoNode.count).to eq(1)

      node = GeoNode.first

      expect(node.schema).to eq('https')
      expect(node.primary).to be_truthy
      expect(node.geo_node_key).to be_nil
    end
  end

  describe 'set_secondary_as_primary task' do
    include ::EE::GeoHelpers

    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }

    before do
      expect(Gitlab::Geo).to receive(:license_allows?).and_return(true)

      stub_current_geo_node(current_node)
    end

    it 'removes primary and sets secondary as primary' do
      run_rake_task('geo:set_secondary_as_primary')

      expect(current_node.primary?).to be_truthy
      expect(GeoNode.count).to eq(1)
    end
  end
end
