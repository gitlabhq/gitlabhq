# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Organization, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:group).with_foreign_key('group_id') }
  end

  describe 'validations' do
    subject { create(:organization) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:group_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end

  describe '#name' do
    it 'strips name' do
      organization = described_class.new(name: '   GitLab   ')
      organization.valid?

      expect(organization.name).to eq('GitLab')
    end
  end

  describe '#find_by_name' do
    let!(:group) { create(:group) }
    let!(:organiztion1) { create(:organization, group: group, name: 'Test') }
    let!(:organiztion2) { create(:organization, group: create(:group), name: 'Test') }

    it 'strips name' do
      expect(described_class.find_by_name(group.id, 'TEST')).to eq([organiztion1])
    end
  end
end
