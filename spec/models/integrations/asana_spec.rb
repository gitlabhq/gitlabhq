# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Asana do
  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :api_key }
    end
  end

  describe 'Execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:gid) { "123456789ABCD" }
    let(:asana_task) { double(::Asana::Resources::Task) }
    let(:asana_integration) { described_class.new }
    let(:ref) { 'main' }
    let(:restrict_to_branch) { nil }

    let(:data) do
      {
        object_kind: 'push',
        ref: ref,
        user_name: user.name,
        commits: [
          {
            message: message,
            url: 'https://gitlab.com/'
          }
        ]
      }
    end

    before do
      allow(asana_integration).to receive_messages(
        project: project,
        project_id: project.id,
        api_key: 'verySecret',
        restrict_to_branch: restrict_to_branch
      )
    end

    subject(:execute_integration) { asana_integration.execute(data) }

    context 'with restrict_to_branch' do
      let(:restrict_to_branch) { 'feature-branch, main' }
      let(:message) { 'fix #456789' }

      context 'when ref is in scope of restriced branches' do
        let(:ref) { 'main' }

        it 'calls the Asana integration' do
          expect(asana_task).to receive(:add_comment)
          expect(asana_task).to receive(:update).with(completed: true)
          expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '456789').once.and_return(asana_task)

          execute_integration
        end
      end

      context 'when ref is not in scope of restricted branches' do
        let(:ref) { 'mai' }

        it 'does not call the Asana integration' do
          expect(asana_task).not_to receive(:add_comment)
          expect(::Asana::Resources::Task).not_to receive(:find_by_id)

          execute_integration
        end
      end
    end

    context 'when creating a story' do
      let(:message) { "Message from commit. related to ##{gid}" }
      let(:expected_message) do
        "#{user.name} pushed to branch main of #{project.full_name} ( https://gitlab.com/ ): #{message}"
      end

      it 'calls Asana integration to create a story' do
        expect(asana_task).to receive(:add_comment).with(text: expected_message)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, gid).once.and_return(asana_task)

        execute_integration
      end
    end

    context 'when creating a story and closing a task' do
      let(:message) { 'fix #456789' }

      it 'calls Asana integration to create a story and close a task' do
        expect(asana_task).to receive(:add_comment)
        expect(asana_task).to receive(:update).with(completed: true)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '456789').once.and_return(asana_task)

        execute_integration
      end
    end

    context 'when closing via url' do
      let(:message) { 'closes https://app.asana.com/19292/956299/42' }

      it 'calls Asana integration to close via url' do
        expect(asana_task).to receive(:add_comment)
        expect(asana_task).to receive(:update).with(completed: true)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '42').once.and_return(asana_task)

        execute_integration
      end
    end

    context 'with multiple matches per line' do
      let(:message) do
        <<-EOF
        minor bigfix, refactoring, fixed #123 and Closes #456 work on #789
        ref https://app.asana.com/19292/956299/42 and closing https://app.asana.com/19292/956299/12
        EOF
      end

      it 'allows multiple matches per line' do
        expect(asana_task).to receive(:add_comment)
        expect(asana_task).to receive(:update).with(completed: true)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '123').once.and_return(asana_task)

        asana_task_2 = double(Asana::Resources::Task)
        expect(asana_task_2).to receive(:add_comment)
        expect(asana_task_2).to receive(:update).with(completed: true)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '456').once.and_return(asana_task_2)

        asana_task_3 = double(Asana::Resources::Task)
        expect(asana_task_3).to receive(:add_comment)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '789').once.and_return(asana_task_3)

        asana_task_4 = double(Asana::Resources::Task)
        expect(asana_task_4).to receive(:add_comment)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '42').once.and_return(asana_task_4)

        asana_task_5 = double(Asana::Resources::Task)
        expect(asana_task_5).to receive(:add_comment)
        expect(asana_task_5).to receive(:update).with(completed: true)
        expect(::Asana::Resources::Task).to receive(:find_by_id).with(anything, '12').once.and_return(asana_task_5)

        execute_integration
      end
    end
  end
end
