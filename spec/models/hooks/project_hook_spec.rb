# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#  note_events           :boolean          default(FALSE), not null
#

require 'spec_helper'

describe ProjectHook do
  describe '.push_hooks' do
    it 'should return hooks for push events only' do
      hook = create(:project_hook, push_events: true)
      create(:project_hook, push_events: false)
      expect(ProjectHook.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'should return hooks for tag push events only' do
      hook = create(:project_hook, tag_push_events: true)
      create(:project_hook, tag_push_events: false)
      expect(ProjectHook.tag_push_hooks).to eq([hook])
    end
  end
end
