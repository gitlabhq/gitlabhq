# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::ReleaseEntity, feature_category: :release_evidence do
  let_it_be(:project) { create(:project) }

  let(:release) { build(:release, project: project) }
  let(:entity) { described_class.new(release) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(
      :id, :tag_name, :name, :description, :created_at, :project, :milestones, :packages
    )
  end

  context 'when the release has milestones' do
    let(:milestone_1) { build(:milestone, project: project) }
    let(:milestone_2) { build(:milestone, project: project) }
    let(:release) { build(:release, project: project, milestones: [milestone_1, milestone_2]) }

    it 'exposes these milestones' do
      expect(subject[:milestones]).to contain_exactly(
        Evidences::MilestoneEntity.new(milestone_1).as_json,
        Evidences::MilestoneEntity.new(milestone_2).as_json
      )
    end
  end

  context 'when the release has no milestone' do
    let(:release) { build(:release, project: project, milestones: []) }

    it 'exposes an empty array for milestones' do
      expect(subject[:milestones]).to be_empty
    end
  end

  context 'when the release has associated packages' do
    let_it_be(:release) { create(:release, project: project, tag: 'v1.0.0') }

    let_it_be(:package) { create(:generic_package, project: project, version: '1.0.0') }

    it 'exposes the packages' do
      expect(subject[:packages]).to contain_exactly(
        a_hash_including(
          id: package.id,
          name: package.name,
          version: '1.0.0',
          package_type: 'generic'
        )
      )
    end
  end

  context 'when the release has no associated packages' do
    let(:release) { create(:release, project: project, tag: 'v2.0.0') }

    it 'exposes an empty array for packages' do
      expect(subject[:packages]).to be_empty
    end
  end
end
