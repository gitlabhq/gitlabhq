require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170710083355_clean_stage_id_reference_migration.rb')

describe CleanStageIdReferenceMigration, :migration, :sidekiq do
  context 'when there are enqueued background migrations' do
    pending 'processes enqueued jobs synchronously' do
      fail
    end
  end

  context 'when there are scheduled background migrations' do
    pending 'immediately processes scheduled jobs' do
      fail
    end
  end

  context 'when there are no background migrations pending' do
    pending 'does nothing' do
      fail
    end
  end
end
