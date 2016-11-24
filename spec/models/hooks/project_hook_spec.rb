require 'spec_helper'

describe ProjectHook, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe '.push_hooks' do
    it 'returns hooks for push events only' do
      hook = create(:project_hook, push_events: true)
      create(:project_hook, push_events: false)
      expect(ProjectHook.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'returns hooks for tag push events only' do
      hook = create(:project_hook, tag_push_events: true)
      create(:project_hook, tag_push_events: false)
      expect(ProjectHook.tag_push_hooks).to eq([hook])
    end
  end
end
