# frozen_string_literal: true

require "spec_helper"

RSpec.describe SystemHook, feature_category: :webhooks do
  it_behaves_like 'a hook that does not get automatically disabled on failure' do
    let(:hook) { build(:system_hook) }
    let(:hook_factory) { :system_hook }
    let(:default_factory_arguments) { {} }

    def find_hooks
      described_class.all
    end
  end

  context 'default attributes' do
    let(:system_hook) { described_class.new }

    it 'sets defined default parameters' do
      attrs = {
        push_events: false,
        repository_update_events: true,
        merge_requests_events: false
      }
      expect(system_hook).to have_attributes(attrs)
    end
  end

  describe 'validations' do
    describe 'url' do
      let(:url) { 'http://localhost:9000' }

      it { is_expected.not_to allow_value(url).for(:url) }

      it 'is valid if application settings allow local requests from system hooks' do
        settings = ApplicationSetting.new(allow_local_requests_from_system_hooks: true)
        allow(ApplicationSetting).to receive(:current).and_return(settings)

        is_expected.to allow_value(url).for(:url)
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:web_hook_logs) }
  end

  describe '#destroy' do
    it 'does not cascade to web_hook_logs' do
      web_hook = create(:system_hook)
      create_list(:web_hook_log, 3, web_hook: web_hook)

      expect { web_hook.destroy! }.not_to change { web_hook.web_hook_logs.count }
    end
  end

  describe "execute", :sidekiq_might_not_need_inline do
    let_it_be(:system_hook) { create(:system_hook) }
    let_it_be(:user) { create(:user) }
    let(:project) { build(:project, namespace: user.namespace) }
    let(:group) { build(:group) }
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jg@example.com', password: User.random_password,
        organization_id: group.organization_id }
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
      user.destroy!

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_destroy/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project member create hook" do
      project.add_maintainer(user)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_add_to_team/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project member destroy hook" do
      project.add_maintainer(user)
      project.project_members.destroy_all # rubocop: disable Cop/DestroyAll

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_remove_from_team/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it "project member update hook" do
      project.add_guest(user)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_update_for_team/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    %i[project group].each do |parent|
      it "#{parent} member access request hook" do
        create(:"#{parent}_member", requested_at: Time.current.utc)

        expect(WebMock).to have_requested(:post, system_hook.url).with(
          body: /user_access_request_to_#{parent}/,
          headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
        ).once
      end

      it "#{parent} member access request revoked hook" do
        member = create(:"#{parent}_member", requested_at: Time.current.utc)
        member.destroy!

        expect(WebMock).to have_requested(:post, system_hook.url).with(
          body: /user_access_request_revoked_for_#{parent}/,
          headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
        ).once
      end
    end

    it 'group create hook' do
      create(:group)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /group_create/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group destroy hook' do
      create(:group).destroy!

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /group_destroy/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group member create hook' do
      group.add_maintainer(user)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_add_to_group/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group member destroy hook' do
      group.add_maintainer(user)
      group.group_members.destroy_all # rubocop: disable Cop/DestroyAll

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_remove_from_group/,
        headers: { 'Content-Type' => 'application/json', 'X-Gitlab-Event' => 'System Hook' }
      ).once
    end

    it 'group member update hook' do
      group = create(:group)
      group.add_guest(user)
      group.add_maintainer(user)

      expect(WebMock).to have_requested(:post, system_hook.url).with(
        body: /user_update_for_group/,
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

    it '#execute' do
      expect(WebHookService).to receive(:new).with(hook, data, hook_name, idempotency_key: anything,
        force: false).and_call_original

      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data, hook_name)
    end

    it '#async_execute' do
      expect(WebHookService).to receive(:new).with(hook, data, hook_name, idempotency_key: anything).and_call_original

      expect_any_instance_of(WebHookService).to receive(:async_execute)

      hook.async_execute(data, hook_name)
    end
  end

  describe '#application_context' do
    let(:hook) { build(:system_hook) }

    it 'includes the type' do
      expect(hook.application_context).to eq(
        related_class: 'SystemHook'
      )
    end
  end

  describe '#pluralized_name' do
    subject { build(:no_sti_system_hook).pluralized_name }

    it { is_expected.to eq('System hooks') }
  end

  describe '#help_path' do
    subject { build(:no_sti_system_hook).help_path }

    it { is_expected.to eq('administration/system_hooks') }
  end
end
