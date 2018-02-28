require 'spec_helper'

describe ProjectHook do
  describe 'associations' do
    it { is_expected.to belong_to :project }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '.push_hooks' do
    it 'returns hooks for push events only' do
      hook = create(:project_hook, push_events: true)
      create(:project_hook, push_events: false)
      expect(described_class.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'returns hooks for tag push events only' do
      hook = create(:project_hook, tag_push_events: true)
      create(:project_hook, tag_push_events: false)
      expect(described_class.tag_push_hooks).to eq([hook])
    end
  end
end
