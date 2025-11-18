# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Level, feature_category: :global_search do
  let(:project_options) { { project_id: 1 } }
  let(:group_options)   { { group_id: 2 } }
  let(:global_options)  { {} }

  describe '#project?' do
    it 'returns true when project_id is present' do
      level = described_class.new(project_options)
      expect(level.project?).to be true
    end

    it 'returns false when project_id is not present' do
      level = described_class.new(group_options)
      expect(level.project?).to be false
      level = described_class.new(global_options)
      expect(level.project?).to be false
    end
  end

  describe '#group?' do
    it 'returns true when group_id is present and project_id is not' do
      level = described_class.new(group_options)
      expect(level.group?).to be true
    end

    it 'returns false when group_id is not present' do
      level = described_class.new(project_options)
      expect(level.group?).to be false
      level = described_class.new(global_options)
      expect(level.group?).to be false
    end
  end

  describe '#global?' do
    it 'returns true when neither project_id nor group_id is present' do
      level = described_class.new(global_options)
      expect(level.global?).to be true
    end

    it 'returns false when project_id or group_id is present' do
      level = described_class.new(project_options)
      expect(level.global?).to be false
      level = described_class.new(group_options)
      expect(level.global?).to be false
    end
  end

  describe '#as_sym' do
    it 'returns :project when project_id is present' do
      level = described_class.new(project_options)
      expect(level.as_sym).to eq :project
    end

    it 'returns :group when group_id is present' do
      level = described_class.new(group_options)
      expect(level.as_sym).to eq :group
    end

    it 'returns :global when neither project_id nor group_id is present' do
      level = described_class.new(global_options)
      expect(level.as_sym).to eq :global
    end

    it 'returns :project when both project_id and group_id are present' do
      options = { project_id: 1, group_id: 2 }
      level = described_class.new(options)
      expect(level.as_sym).to eq :project
      expect(level.project?).to be true
      expect(level.group?).to be false
      expect(level.global?).to be false
    end
  end
end
