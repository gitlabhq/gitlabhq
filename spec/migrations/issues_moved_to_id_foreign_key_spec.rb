require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171106151218_issues_moved_to_id_foreign_key.rb')

describe IssuesMovedToIdForeignKey, :migration do
  let(:issues) { table(:issues) }

  let!(:issue_third) { issues.create! }
  let!(:issue_second) { issues.create!(moved_to_id: issue_third.id) }
  let!(:issue_first) { issues.create!(moved_to_id: issue_second.id) }

  subject { described_class.new }

  it 'removes the orphaned moved_to_id' do
    subject.down

    issue_third.update!(moved_to_id: 0)

    subject.up

    expect(issue_first.reload.moved_to_id).to eq(issue_second.id)
    expect(issue_second.reload.moved_to_id).to eq(issue_third.id)
    expect(issue_third.reload.moved_to_id).to be_nil
  end
end
