# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Needed in specs

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MarkSingleIssuableResourceLinks, feature_category: :database do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:issuable_resource_links) { table(:issuable_resource_links) }
  let(:issue_base_type_enum_value) { 0 }
  let(:issue_type) { table(:work_item_types).find_by!(base_type: issue_base_type_enum_value) }

  let(:user) { create_user(email: "test1@example.com", username: "test1") }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:namespace) do
    namespaces.create!(name: "test-1", path: "test-1", owner_id: user.id, organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      id: 9999,
      organization_id: organization.id,
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      creator_id: user.id
    )
  end

  let!(:issue1) { create_issue }
  let!(:issue2) { create_issue }

  let!(:issuable_resource_link1) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link1", is_unique: false) }
  let!(:issuable_resource_link1_alt1) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link1alt", is_unique: false) }
  let!(:issuable_resource_link1_alt2) { issuable_resource_links.create!(issue_id: issue2.id, link: "https://gitlab.com/link1", is_unique: false) }
  let!(:issuable_resource_link2) do
    irl = issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link2")
    irl.update!(is_unique: true)
    irl
  end

  let!(:issuable_resource_link2_alt1) do
    irl = issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link2alt")
    irl.update!(is_unique: true)
    irl
  end

  let!(:issuable_resource_link2_alt2) do
    irl = issuable_resource_links.create!(issue_id: issue2.id, link: "https://gitlab.com/link2")
    irl.update!(is_unique: true)
    irl
  end

  let!(:issuable_resource_link3) do
    irl = issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link3")
    irl.update!(is_unique: nil)
    irl
  end

  let!(:issuable_resource_link3_alt1) do
    irl = issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link3alt")
    irl.update!(is_unique: nil)
    irl
  end

  let!(:issuable_resource_link3_alt2) do
    irl = issuable_resource_links.create!(issue_id: issue2.id, link: "https://gitlab.com/link3")
    irl.update!(is_unique: nil)
    irl
  end

  let!(:issuable_resource_link4) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link4", is_unique: true) }
  let!(:issuable_resource_link4_dup) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link4", is_unique: false) }
  let!(:issuable_resource_link5) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link5", is_unique: false) }
  let!(:issuable_resource_link5_dup) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link5", is_unique: false) }
  let!(:issuable_resource_link6) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link6", is_unique: nil) }
  let!(:issuable_resource_link6_dup) { issuable_resource_links.create!(issue_id: issue1.id, link: "https://gitlab.com/link6", is_unique: nil) }

  let(:stating_id) { issuable_resource_links.pluck(:issue_id).min }
  let(:end_id) { issuable_resource_links.pluck(:issue_id).max }

  subject(:migration) do
    described_class.new(
      start_id: stating_id,
      end_id: end_id,
      batch_table: :issuable_resource_links,
      batch_column: :issue_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  it 'marks single issuable links as unique' do
    expect(issuable_resource_links.find(issuable_resource_link1.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link1_alt1.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link1_alt2.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link2.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link2_alt1.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link2_alt2.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link3.id).is_unique).to be_nil
    expect(issuable_resource_links.find(issuable_resource_link3_alt1.id).is_unique).to be_nil
    expect(issuable_resource_links.find(issuable_resource_link3_alt2.id).is_unique).to be_nil
    expect(issuable_resource_links.find(issuable_resource_link4.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link4_dup.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link5.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link5_dup.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link6.id).is_unique).to be_nil
    expect(issuable_resource_links.find(issuable_resource_link6_dup.id).is_unique).to be_nil

    expect { migration.perform }.not_to change { issuable_resource_links.count }

    expect(issuable_resource_links.find(issuable_resource_link1.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link1_alt1.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link1_alt2.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link2.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link2_alt1.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link2_alt2.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link3.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link3_alt1.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link3_alt2.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link4.id).is_unique).to be(true)
    expect(issuable_resource_links.find(issuable_resource_link4_dup.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link5.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link5_dup.id).is_unique).to be(false)
    expect(issuable_resource_links.find(issuable_resource_link6.id).is_unique).to be_nil
    expect(issuable_resource_links.find(issuable_resource_link6_dup.id).is_unique).to be_nil
  end

  private

  def create_issue
    issues.create!(
      title: 'title',
      description: 'description',
      project_id: project.id,
      namespace_id: project.project_namespace_id,
      work_item_type_id: issue_type.id
    )
  end

  def create_user(overrides = {})
    attrs = {
      email: "test@example.com",
      notification_email: "test@example.com",
      name: "test",
      username: "test",
      state: "active",
      projects_limit: 10
    }.merge(overrides)

    users.create!(attrs)
  end
end

# rubocop:enable RSpec/MultipleMemoizedHelpers
