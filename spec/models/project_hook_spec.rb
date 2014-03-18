require 'spec_helper'

describe ProjectHook do
  describe '.push_hooks' do
    it 'should return hooks for push events only' do
      hook = create(:project_hook, push_events: true)
      hook2 = create(:project_hook, push_events: false)
      expect(ProjectHook.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'should return hooks for tag push events only' do
      hook = create(:project_hook, tag_push_events: true)
      hook2 = create(:project_hook, tag_push_events: false)
      expect(ProjectHook.tag_push_hooks).to eq([hook])
    end
  end
end
