# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170406142253_migrate_user_project_view.rb')

describe MigrateUserProjectView, :migration do
  let(:migration) { described_class.new }
  let!(:user) { table(:users).create!(project_view: User.project_views['readme']) }

  describe '#up' do
    it 'updates project view setting with new value' do
      migration.up

      expect(user.reload.project_view).to eq(User.project_views['files'])
    end
  end
end
