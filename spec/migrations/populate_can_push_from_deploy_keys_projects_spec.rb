require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171215113714_populate_can_push_from_deploy_keys_projects.rb')

describe PopulateCanPushFromDeployKeysProjects, :migration do
  let(:migration) { described_class.new }
  let(:deploy_keys) { table(:keys) }
  let(:deploy_keys_projects) { table(:deploy_keys_projects) }
  let(:projects) { table(:projects) }

  before do
    deploy_keys.inheritance_column = nil

    projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1')
    (1..10).each do |index|
      deploy_keys.create!(id: index, title: 'dummy', type: 'DeployKey', key: Spec::Support::Helpers::KeyGeneratorHelper.new(1024).generate + ' dummy@gitlab.com')
      deploy_keys_projects.create!(id: index, deploy_key_id: index, project_id: 1)
    end
  end

  describe '#up' do
    it 'migrates can_push from deploy_keys to deploy_keys_projects' do
      deploy_keys.limit(5).update_all(can_push: true)

      expected = deploy_keys.order(:id).pluck(:id, :can_push)

      migration.up

      expect(deploy_keys_projects.order(:id).pluck(:deploy_key_id, :can_push)).to eq expected
    end
  end

  describe '#down' do
    it 'migrates can_push from deploy_keys_projects to deploy_keys' do
      deploy_keys_projects.limit(5).update_all(can_push: true)

      expected = deploy_keys_projects.order(:id).pluck(:deploy_key_id, :can_push)

      migration.down

      expect(deploy_keys.order(:id).pluck(:id, :can_push)).to eq expected
    end
  end
end
