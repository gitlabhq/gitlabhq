# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::ReleaseEntity do
  let(:release) { build(:release) }
  let(:entity) { described_class.new(release) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:id, :tag_name, :name, :description, :created_at, :project, :milestones)
  end

  context 'when the release has milestones' do
    let(:project) { create(:project) }
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
    let(:release) { build(:release, milestones: []) }

    it 'exposes an empty array for milestones' do
      expect(subject[:milestones]).to be_empty
    end
  end
end
