require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171106151218_issues_moved_to_id_foreign_key.rb')

# The schema version has to be far enough in advance to have the
# only_mirror_protected_branches column in the projects table to create a
# project via FactoryBot.
describe IssuesMovedToIdForeignKey, :migration, schema: 20171114150259 do
  let!(:issue_first) { create(:issue, moved_to_id: issue_second.id) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:issue_second) { create(:issue, moved_to_id: issue_third.id) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:issue_third) { create(:issue) } # rubocop:disable RSpec/FactoriesInMigrationSpecs

  subject { described_class.new }

  it 'removes the orphaned moved_to_id' do
    subject.down

    issue_third.update_attributes(moved_to_id: 100000)

    subject.up

    expect(issue_first.reload.moved_to_id).to eq(issue_second.id)
    expect(issue_second.reload.moved_to_id).to eq(issue_third.id)
    expect(issue_third.reload.moved_to_id).to be_nil
  end
end
