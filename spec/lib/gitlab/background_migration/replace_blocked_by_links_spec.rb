# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ReplaceBlockedByLinks, schema: 20201015073808 do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, name: 'gitlab') }
  let(:issue1) { table(:issues).create!(project_id: project.id, title: 'a') }
  let(:issue2) { table(:issues).create!(project_id: project.id, title: 'b') }
  let(:issue3) { table(:issues).create!(project_id: project.id, title: 'c') }
  let(:issue_links) { table(:issue_links) }
  let!(:blocked_link1) { issue_links.create!(source_id: issue2.id, target_id: issue1.id, link_type: 2) }
  let!(:opposite_link1) { issue_links.create!(source_id: issue1.id, target_id: issue2.id, link_type: 1) }
  let!(:blocked_link2) { issue_links.create!(source_id: issue1.id, target_id: issue3.id, link_type: 2) }
  let!(:opposite_link2) { issue_links.create!(source_id: issue3.id, target_id: issue1.id, link_type: 0) }
  let!(:nochange_link) { issue_links.create!(source_id: issue2.id, target_id: issue3.id, link_type: 1) }

  subject { described_class.new.perform(issue_links.minimum(:id), issue_links.maximum(:id)) }

  it 'deletes any opposite relations' do
    subject

    expect(issue_links.ids).to match_array([nochange_link.id, blocked_link1.id, blocked_link2.id])
  end

  it 'ignores issue links other than blocked_by' do
    subject

    expect(nochange_link.reload.link_type).to eq(1)
  end

  it 'updates blocked_by issue links' do
    subject

    expect(blocked_link1.reload.link_type).to eq(1)
    expect(blocked_link1.source_id).to eq(issue1.id)
    expect(blocked_link1.target_id).to eq(issue2.id)
    expect(blocked_link2.reload.link_type).to eq(1)
    expect(blocked_link2.source_id).to eq(issue3.id)
    expect(blocked_link2.target_id).to eq(issue1.id)
  end
end
