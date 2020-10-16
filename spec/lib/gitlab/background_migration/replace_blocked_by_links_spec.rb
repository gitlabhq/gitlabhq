# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ReplaceBlockedByLinks, schema: 20201015073808 do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, name: 'gitlab') }
  let(:issue1) { table(:issues).create!(project_id: project.id, title: 'a') }
  let(:issue2) { table(:issues).create!(project_id: project.id, title: 'b') }
  let(:issue3) { table(:issues).create!(project_id: project.id, title: 'c') }
  let(:issue_links) { table(:issue_links) }
  let!(:blocks_link) { issue_links.create!(source_id: issue1.id, target_id: issue2.id, link_type: 1) }
  let!(:bidirectional_link) { issue_links.create!(source_id: issue2.id, target_id: issue1.id, link_type: 2) }
  let!(:blocked_link) { issue_links.create!(source_id: issue1.id, target_id: issue3.id, link_type: 2) }

  subject { described_class.new.perform(issue_links.minimum(:id), issue_links.maximum(:id)) }

  it 'deletes issue links where opposite relation already exists' do
    expect { subject }.to change { issue_links.count }.by(-1)
  end

  it 'ignores issue links other than blocked_by' do
    subject

    expect(blocks_link.reload.link_type).to eq(1)
  end

  it 'updates blocked_by issue links' do
    subject

    link = blocked_link.reload
    expect(link.link_type).to eq(1)
    expect(link.source_id).to eq(issue3.id)
    expect(link.target_id).to eq(issue1.id)
  end
end
