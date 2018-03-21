require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170815060945_remove_duplicate_mr_events.rb')

describe RemoveDuplicateMrEvents, :delete do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:user) { create(:user) }
    let(:merge_requests) { create_list(:merge_request, 2) }
    let(:issue) { create(:issue) }
    let!(:events) do
      [
        create(:event, :created, author: user, target: merge_requests.first),
        create(:event, :created, author: user, target: merge_requests.first),
        create(:event, :updated, author: user, target: merge_requests.first),
        create(:event, :created, author: user, target: merge_requests.second),
        create(:event, :created, author: user, target: issue),
        create(:event, :created, author: user, target: issue)
      ]
    end

    it 'removes duplicated merge request create records' do
      expect { migration.up }.to change { Event.count }.from(6).to(5)
    end
  end
end
