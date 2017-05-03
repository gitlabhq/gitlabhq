require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170106142508_fill_authorized_projects.rb')

describe FillAuthorizedProjects do
  describe '#up' do
    it 'schedules the jobs in batches' do
      user1 = create(:user)
      user2 = create(:user)

      expect(Sidekiq::Client).to receive(:push_bulk).with(
        'class' => 'AuthorizedProjectsWorker',
        'args'  => [[user1.id], [user2.id]]
      )

      described_class.new.up
    end
  end
end
