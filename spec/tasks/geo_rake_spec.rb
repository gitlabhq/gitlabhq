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
end
