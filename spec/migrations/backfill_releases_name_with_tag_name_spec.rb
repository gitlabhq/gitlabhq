# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20181212104941_backfill_releases_name_with_tag_name.rb')

describe BackfillReleasesNameWithTagName, :migration do
  let(:releases)   { table(:releases) }
  let(:namespaces) { table(:namespaces) }
  let(:projects)   { table(:projects) }

  let(:namespace)  { namespaces.create(name: 'foo', path: 'foo') }
  let(:project)    { projects.create!(namespace_id: namespace.id) }
  let(:release)    { releases.create!(project_id: project.id, tag: 'v1.0.0') }

  it 'defaults name to tag value' do
    expect(release.tag).to be_present

    migrate!

    release.reload
    expect(release.name).to eq(release.tag)
  end
end
