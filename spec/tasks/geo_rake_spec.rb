require 'rake_helper'

describe 'geo rake tasks' do
  before do
    Rake.application.rake_require 'tasks/geo'
  end

  describe 'set_primary_node task' do
    let(:ssh_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUkxk8m9rVYZ1q4/5xpg3TwTM9QFw3TinPFkyWsiACFKjor3byV6g3vHWTuIS70E7wk2JTXGL0wdrfUG6iQDJuP0BYNxjkluB14nIAfPuXN7V73QY/cqvHogw5o6pPRFD+Szke6FzouNQ70Z/qrM1k7me3e9DMuscMMrMTOR2HLKppNQyP4Jp0WJOyncdWB2NxKXTezy/ZnHv+BdhC0q0JW3huIx9qkBCHio7x8BdyJLMF9KxNYIuCkbP3exs5wgb+qGrjSri6LfAVq8dJ2VYibWxdsUG6iITJF+G4qbcyQjgiMLbxCfNd9bjwmkxSGvFn2EPsAFKzxyAvYFWb/y91 test@host' }

    before do
      expect(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      stub_config_setting(protocol: 'https')
    end

    it 'creates a GeoNode' do
      begin
        file = Tempfile.new('geo-test-')
        file.write(ssh_key)
        path = file.path
        file.close

        expect(GeoNode.count).to eq(0)

        run_rake_task('geo:set_primary_node', path)

        expect(GeoNode.count).to eq(1)
        node = GeoNode.first
        expect(node.schema).to eq('https')
        expect(node.primary).to be_truthy
        expect(node.geo_node_key.key).to eq(ssh_key)
      ensure
        file.unlink
      end
    end
  end
end
