# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemHooksService do
  describe '#execute_hooks_for' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }
    let_it_be(:group_member) { create(:group_member, source: group, user: user) }
    let_it_be(:project_member) { create(:project_member, source: project, user: user) }
    let_it_be(:key) { create(:key, user: user) }
    let_it_be(:deploy_key) { create(:key) }

    let(:event) { :create }

    using RSpec::Parameterized::TableSyntax

    where(:model_name, :builder_class) do
      :group_member | Gitlab::HookData::GroupMemberBuilder
      :group | Gitlab::HookData::GroupBuilder
      :project_member | Gitlab::HookData::ProjectMemberBuilder
      :user | Gitlab::HookData::UserBuilder
      :project | Gitlab::HookData::ProjectBuilder
      :key | Gitlab::HookData::KeyBuilder
      :deploy_key | Gitlab::HookData::KeyBuilder
    end

    with_them do
      it 'builds the data with the relevant builder class and then calls #execute_hooks with the obtained data' do
        data = double
        model = public_send(model_name)

        expect_next_instance_of(builder_class, model) do |builder|
          expect(builder).to receive(:build).with(event).and_return(data)
        end

        service = described_class.new

        expect_next_instance_of(SystemHooksService) do |system_hook_service|
          expect(system_hook_service).to receive(:execute_hooks).with(data)
        end

        service.execute_hooks_for(model, event)
      end
    end
  end

  describe '#execute_hooks' do
    let(:data) { { key: :value } }

    subject { described_class.new.execute_hooks(data) }

    it 'executes system hooks with the given data' do
      hook = create(:system_hook)

      allow(SystemHook).to receive_message_chain(:hooks_for, :find_each).and_yield(hook)

      expect(hook).to receive(:async_execute).with(data, 'system_hooks')

      subject
    end

    it 'executes FileHook with the given data' do
      expect(Gitlab::FileHook).to receive(:execute_all_async).with(data)

      subject
    end
  end
end
