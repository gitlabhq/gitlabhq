require "spec_helper"

describe SystemHook do
  context 'default attributes' do
    let(:system_hook) { build(:system_hook) }

    it 'sets defined default parameters' do
      attrs = {
        push_events: false,
        repository_update_events: true,
        merge_requests_events: false
      }
      expect(system_hook).to have_attributes(attrs)
    end
  end

  describe "execute" do
    let(:system_hook) { create(:system_hook) }
    let(:user)        { create(:user) }
    let(:project)     { create(:project, namespace: user.namespace) }
    let(:group)       { create(:group) }
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jg@example.com', password: 'mydummypass' }
    end

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
      Users::CreateService.new(nil, params).execute

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
      project.add_master(user)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_add_to_team/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project_destroy hook" do
      project.add_master(user)
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

  describe '.repository_update_hooks' do
    it 'returns hooks for repository update events only' do
      hook = create(:system_hook, repository_update_events: true)
      create(:system_hook, repository_update_events: false)
      expect(described_class.repository_update_hooks).to eq([hook])
    end
  end

  describe 'execute WebHookService' do
    let(:hook) { build(:system_hook) }
    let(:data) { { key: 'value' } }
    let(:hook_name) { 'system_hook' }

    before do
      expect(WebHookService).to receive(:new).with(hook, data, hook_name).and_call_original
    end

    it '#execute' do
      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data, hook_name)
    end

    it '#async_execute' do
      expect_any_instance_of(WebHookService).to receive(:async_execute)

      hook.async_execute(data, hook_name)
    end
  end
end
