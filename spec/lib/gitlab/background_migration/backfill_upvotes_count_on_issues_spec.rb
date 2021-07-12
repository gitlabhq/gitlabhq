# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUpvotesCountOnIssues, schema: 20210701111909 do
  let(:award_emoji) { table(:award_emoji) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project1) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:project2) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:issue1) { table(:issues).create!(project_id: project1.id) }
  let!(:issue2) { table(:issues).create!(project_id: project2.id) }
  let!(:issue3) { table(:issues).create!(project_id: project2.id) }
  let!(:issue4) { table(:issues).create!(project_id: project2.id) }

  describe '#perform' do
    before do
      add_upvotes(issue1, :thumbsdown, 1)
      add_upvotes(issue2, :thumbsup, 2)
      add_upvotes(issue2, :thumbsdown, 1)
      add_upvotes(issue3, :thumbsup, 3)
      add_upvotes(issue4, :thumbsup, 4)
    end

    it 'updates upvotes_count' do
      subject.perform(issue1.id, issue4.id)

      expect(issue1.reload.upvotes_count).to eq(0)
      expect(issue2.reload.upvotes_count).to eq(2)
      expect(issue3.reload.upvotes_count).to eq(3)
      expect(issue4.reload.upvotes_count).to eq(4)
    end
  end

  private

  def add_upvotes(issue, name, count)
    count.times do
      award_emoji.create!(
        name: name.to_s,
        awardable_type: 'Issue',
        awardable_id: issue.id
      )
    end
  end
end
