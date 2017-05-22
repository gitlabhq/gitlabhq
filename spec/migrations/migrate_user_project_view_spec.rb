# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170406142253_migrate_user_project_view.rb')

describe MigrateUserProjectView do
  let(:migration) { described_class.new }
  let!(:user) { create(:user) }

  before do
    # 0 is the numeric value for the old 'readme' option
    user.update_column(:project_view, 0)
  end

  describe '#up' do
    it 'updates project view setting with new value' do
      migration.up

      expect(user.reload.project_view).to eq('files')
    end
  end
end
