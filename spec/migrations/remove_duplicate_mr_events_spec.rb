require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170815060945_remove_duplicate_mr_events.rb')

describe RemoveDuplicateMrEvents, :delete do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:user) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
    let(:merge_requests) { create_list(:merge_request, 2) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
    let(:issue) { create(:issue) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
    let!(:events) do
      [
        create(:event, :created, author: user, target: merge_requests.first), # rubocop:disable RSpec/FactoriesInMigrationSpecs
        create(:event, :created, author: user, target: merge_requests.first), # rubocop:disable RSpec/FactoriesInMigrationSpecs
        create(:event, :updated, author: user, target: merge_requests.first), # rubocop:disable RSpec/FactoriesInMigrationSpecs
        create(:event, :created, author: user, target: merge_requests.second), # rubocop:disable RSpec/FactoriesInMigrationSpecs
        create(:event, :created, author: user, target: issue), # rubocop:disable RSpec/FactoriesInMigrationSpecs
        create(:event, :created, author: user, target: issue) # rubocop:disable RSpec/FactoriesInMigrationSpecs
      ]
    end

    it 'removes duplicated merge request create records' do
      expect { migration.up }.to change { Event.count }.from(6).to(5)
    end
  end
end
