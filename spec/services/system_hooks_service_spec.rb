# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemHooksService, feature_category: :webhooks do
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

    where(:model_name, :builder_class, :organization_source) do
      :group_member | Gitlab::HookData::GroupMemberBuilder | :source
      :group | Gitlab::HookData::GroupBuilder | :self
      :project_member | Gitlab::HookData::ProjectMemberBuilder | :source
      :user | Gitlab::HookData::UserBuilder | :self
      :project | Gitlab::HookData::ProjectBuilder | :self
      :key | Gitlab::HookData::KeyBuilder | :self
      :deploy_key | Gitlab::HookData::KeyBuilder | :self
    end

    with_them do
      it 'builds the data with the relevant builder class and then calls #execute_hooks with the obtained data' do
        data = double
        model = public_send(model_name)

        expect_next_instance_of(builder_class, model) do |builder|
          if builder_class == Gitlab::HookData::ProjectBuilder
            expect(builder).to receive(:build).with(event, include_deprecated_owner: true).and_return(data)
          else
            expect(builder).to receive(:build).with(event).and_return(data)
          end
        end

        service = described_class.new
        organization = organization_source == :source ? model.source.organization : model.organization

        expect_next_instance_of(SystemHooksService) do |system_hook_service|
          expect(system_hook_service).to receive(:execute_hooks).with(data, organization: organization)
        end

        service.execute_hooks_for(model, event)
      end
    end
  end

  describe '#execute_hooks_for with hooks in multiple organizations' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:user) { create(:user, organization: organization) }
    let_it_be(:group) { create(:group, organization: organization) }
    let_it_be(:project) { create(:project, group: group, organization: organization) }

    let_it_be_with_refind(:group_member) { create(:group_member, source: group, user: user) }
    let_it_be_with_refind(:project_member) do
      create(:project_member, source: project, user: create(:user, organization: organization))
    end

    let_it_be_with_refind(:key) { create(:key, user: user) }
    let_it_be_with_refind(:deploy_key) { create(:deploy_key, organization: organization) }

    where(model_name: %i[project group user group_member project_member key deploy_key])

    with_them do
      it_behaves_like 'system hook delivery scoped to the organization' do
        def execute_system_hooks
          described_class.new.execute_hooks_for(public_send(model_name), :create)
        end
      end
    end
  end

  describe '#execute_hooks' do
    let(:data) { { key: :value } }
    let_it_be(:organization) { create(:organization) }

    subject { described_class.new.execute_hooks(data, organization: organization) }

    it 'executes system hooks with the given data' do
      hook = create(:system_hook, organization: organization)

      allow(SystemHook).to receive_message_chain(:for_organization, :executable, :hooks_for, :find_each).and_yield(hook)

      expect(hook).to receive(:async_execute).with(data, 'system_hooks')

      subject
    end

    it 'executes FileHook with the given data' do
      expect(Gitlab::FileHook).to receive(:execute_all_async).with(data)

      subject
    end

    it_behaves_like 'system hook delivery scoped to the organization' do
      def execute_system_hooks
        described_class.new.execute_hooks(data, organization: organization)
      end
    end

    it 'requires an organization' do
      expect { described_class.new.execute_hooks(data) }.to raise_error(ArgumentError, /organization/)
    end

    context 'when the organization is nil' do
      subject { described_class.new.execute_hooks(data, organization: nil) }

      it 'does not execute any system hooks and logs a warning' do
        create(:system_hook, organization: organization)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          a_hash_including(message: 'System hooks not executed: organization could not be resolved')
        )
        expect(WebHookWorker).not_to receive(:perform_async)

        subject
      end

      it 'still executes FileHook with the given data' do
        expect(Gitlab::FileHook).to receive(:execute_all_async).with(data)

        subject
      end
    end
  end
end
