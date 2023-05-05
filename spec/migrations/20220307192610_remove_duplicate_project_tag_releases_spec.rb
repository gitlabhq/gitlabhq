# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDuplicateProjectTagReleases, feature_category: :release_orchestration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:releases) { table(:releases) }

  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }

  let(:dup_releases) do
    Array.new(4).fill do |i|
      rel = releases.new(project_id: project.id, tag: "duplicate tag", released_at: (DateTime.now + i.days))
      rel.save!(validate: false)
      rel
    end
  end

  let(:valid_release) do
    releases.create!(
      project_id: project.id,
      tag: "valid tag",
      released_at: DateTime.now
    )
  end

  describe '#up' do
    it "correctly removes duplicate tags from the same project" do
      expect(dup_releases.length).to eq 4
      expect(valid_release).not_to be nil
      expect(releases.where(tag: 'duplicate tag').count).to eq 4
      expect(releases.where(tag: 'valid tag').count).to eq 1

      migrate!

      expect(releases.where(tag: 'duplicate tag').count).to eq 1
      expect(releases.where(tag: 'valid tag').count).to eq 1
      expect(releases.all.map(&:tag)).to match_array ['valid tag', 'duplicate tag']
    end
  end
end
