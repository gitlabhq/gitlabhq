# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170406142253_migrate_user_project_view.rb')

describe MigrateUserProjectView, :delete do
  let(:migration) { described_class.new }
  let!(:user) { create(:user, project_view: 'readme') }

  describe '#up' do
    it 'updates project view setting with new value' do
      migration.up

      expect(user.reload.project_view).to eq('files')
    end
  end
end
