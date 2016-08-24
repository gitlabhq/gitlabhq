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

require "spec_helper"

describe SystemHook, models: true do
  describe "execute" do
    let(:system_hook) { create(:system_hook) }
    let(:user)        { create(:user) }
    let(:project)     { create(:project, namespace: user.namespace) }
    let(:group)       { create(:group) }

    before do
      WebMock.stub_request(:post, system_hook.url)
    end

    it "project_create hook" do
      Projects::CreateService.new(user, name: 'empty').execute
      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /project_create/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project_destroy hook" do
      Projects::DestroyService.new(project, user, {}).async_execute

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /project_destroy/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "user_create hook" do
      create(:user)
      
      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_create/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "user_destroy hook" do
      user.destroy

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_destroy/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project_create hook" do
      project.team << [user, :master]

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_add_to_team/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project_destroy hook" do
      project.team << [user, :master]
      project.project_members.destroy_all

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_remove_from_team/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group create hook' do
      create(:group)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /group_create/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group destroy hook' do
      group.destroy

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /group_destroy/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group member create hook' do
      group.add_master(user)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_add_to_group/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group member destroy hook' do
      group.add_master(user)
      group.group_members.destroy_all

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_remove_from_group/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end
  end
end
