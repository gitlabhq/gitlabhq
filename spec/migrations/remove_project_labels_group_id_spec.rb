# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180202111106_remove_project_labels_group_id.rb')

describe RemoveProjectLabelsGroupId, :delete do
  let(:migration) { described_class.new }
  let(:group) { create(:group) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:project_label) { create(:label, group_id: group.id) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:group_label) { create(:group_label) } # rubocop:disable RSpec/FactoriesInMigrationSpecs

  describe '#up' do
    it 'updates the project labels group ID' do
      expect { migration.up }.to change { project_label.reload.group_id }.to(nil)
    end

    it 'keeps the group labels group ID' do
      expect { migration.up }.not_to change { group_label.reload.group_id }
    end
  end
end
