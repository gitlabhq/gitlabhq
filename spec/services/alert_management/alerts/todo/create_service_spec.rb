# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::Alerts::Todo::CreateService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert) }

  let(:current_user) { user }

  describe '#execute' do
    subject(:result) { described_class.new(alert, current_user).execute }

    shared_examples 'permissions error' do
      it 'returns an error', :aggregate_failures do
        expect(result.error?).to be(true)
        expect(result.message).to eq('You have insufficient permissions to create a Todo for this alert')
        expect(result.payload[:todo]).to be(nil)
        expect(result.payload[:alert]).to be(alert)
      end
    end

    context 'when the user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'permissions error'
    end

    context 'when the user does not have permission' do
      it_behaves_like 'permissions error'
    end

    context 'when user has permission' do
      before do
        alert.project.add_developer(user)
      end

      it 'creates a todo' do
        expect { result }.to change { Todo.count }.by(1)
      end

      it 'returns the alert and todo in the payload', :aggregate_failures do
        expect(result.success?).to be(true)
        expect(result.payload[:alert][:id]).to be(alert.id)
        expect(result.payload[:todo][:id]).to be(Todo.last.id)
      end

      context 'when the user has a marked todo for the alert' do
        let_it_be(:todo_params) do
          { project: alert.project,
            target: alert,
            user: user,
            action: Todo::MARKED }
        end

        context 'when todo is pending' do
          before_all do
            create(:todo, :pending, **todo_params)
          end

          it 'does not create a todo' do
            expect { result }.not_to change { Todo.count }
          end

          it 'returns an error', :aggregate_failures do
            expect(result.error?).to be(true)
            expect(result.message).to be('You already have pending todo for this alert')
            expect(result.payload[:todo]).to be(nil)
            expect(result.payload[:alert]).to be(alert)
          end
        end

        context 'when todo is done' do
          before do
            create(:todo, :done, **todo_params)
          end

          it { expect(result.success?).to be(true) }
          it { expect { result }.to change { Todo.count }.by(1) }
        end
      end
    end
  end
end
