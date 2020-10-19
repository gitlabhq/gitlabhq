# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestoneRelease do
  let(:project) { create(:project) }
  let(:release) { create(:release, project: project) }
  let(:milestone) { create(:milestone, project: project) }

  subject { build(:milestone_release, release: release, milestone: milestone) }

  describe 'associations' do
    it { is_expected.to belong_to(:release) }
    it { is_expected.to belong_to(:milestone) }
  end

  context 'when trying to create the same record in milestone_releases twice' do
    it 'is not committing on the second time' do
      create(:milestone_release, milestone: milestone, release: release)

      expect do
        subject.save!
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'validations' do
    subject(:milestone_release) { build(:milestone_release, milestone: milestone, release: release) }

    context 'when milestone and release do not have the same project' do
      it 'is not valid' do
        milestone_release.release = build(:release, project: create(:project))

        expect(milestone_release).not_to be_valid
      end
    end

    context 'when milestone and release have the same project' do
      it { is_expected.to be_valid }
    end
  end
end
