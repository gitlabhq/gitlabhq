# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::Alerts::UpdateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:other_user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project, developers: [user_with_permissions, other_user_with_permissions]) }
  let_it_be(:alert, reload: true) { create(:alert_management_alert, :triggered, project: project) }

  let(:current_user) { user_with_permissions }
  let(:params) { {} }

  let(:service) { described_class.new(alert, current_user, params) }

  describe '#execute' do
    shared_examples 'does not add a todo' do
      specify { expect { response }.not_to change(Todo, :count) }
    end

    shared_examples 'does not add a system note' do
      specify { expect { response }.not_to change(Note, :count) }
    end

    shared_examples 'adds a system note' do |note_matcher = nil|
      specify do
        expect { response }.to change { alert.reload.notes.count }.by(1)
        expect(alert.notes.last.note).to match(note_matcher) if note_matcher
      end
    end

    shared_examples 'error response' do |message|
      it_behaves_like 'does not add a todo'
      it_behaves_like 'does not add a system note'

      it 'has an informative message' do
        expect(response).to be_error
        expect(response.message).to eq(message)
      end
    end

    subject(:response) { service.execute }

    context 'when the current_user is nil' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have no permissions'
    end

    context 'when current_user does not have permission to update alerts' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have no permissions'
    end

    context 'when no parameters are included' do
      it_behaves_like 'error response', 'Please provide attributes to update'
    end

    context 'when an error occurs during update' do
      let(:params) { { title: nil } }

      it_behaves_like 'error response', "Title can't be blank"
    end

    shared_examples 'title update' do
      it_behaves_like 'does not add a todo'
      it_behaves_like 'does not add a system note'

      it 'updates the attribute' do
        original_title = alert.title

        expect { response }.to change { alert.title }.from(original_title).to(expected_title)
        expect(response).to be_success
      end
    end

    context 'when a model attribute is included without assignees' do
      let(:params) { { title: 'This is an updated alert.' } }
      let(:expected_title) { params[:title] }

      it_behaves_like 'title update'
    end

    context 'when alert is resolved and another existing unresolved alert' do
      let!(:alert) { create(:alert_management_alert, :resolved, project: project) }
      let!(:existing_alert) { create(:alert_management_alert, :triggered, project: project) }

      let(:params) { { title: 'This is an updated alert.' } }
      let(:expected_title) { params[:title] }

      it_behaves_like 'title update'
    end

    context 'when assignees are included' do
      shared_examples 'adds a todo' do
        let(:assignee) { expected_assignees.first }

        specify do
          expect { response }.to change { assignee.reload.todos.count }.by(1)
          expect(assignee.todos.last.author).to eq(current_user)
        end
      end

      shared_examples 'successful assignment' do
        it_behaves_like 'adds a system note'
        it_behaves_like 'adds a todo'

        after do
          alert.assignees = []
        end

        specify do
          expect { response }.to change { alert.reload.assignees }.from([]).to(expected_assignees)
          expect(response).to be_success
        end
      end

      let(:expected_assignees) { params[:assignees] }

      context 'when the assignee is the current user' do
        let(:params) { { assignees: [current_user] } }

        it_behaves_like 'successful assignment'
      end

      context 'when the assignee has read permissions' do
        let(:params) { { assignees: [other_user_with_permissions] } }

        it_behaves_like 'successful assignment'
      end

      context 'when the assignee does not have read permissions' do
        let(:params) { { assignees: [user_without_permissions] } }

        it_behaves_like 'error response', 'Assignee has no permissions'
      end

      context 'when user is already assigned' do
        let(:params) { { assignees: [user_with_permissions] } }

        before do
          alert.assignees << user_with_permissions
        end

        it_behaves_like 'does not add a system note'
        it_behaves_like 'does not add a todo'
      end

      context 'with multiple users included' do
        let(:params) { { assignees: [user_with_permissions, user_without_permissions] } }
        let(:expected_assignees) { [user_with_permissions] }

        it_behaves_like 'successful assignment'
      end
    end

    context 'when a status is included' do
      let(:params) { { status: new_status } }
      let(:new_status) { :acknowledged }

      it 'successfully changes the status' do
        expect { response }.to change { alert.acknowledged? }.to(true)
        expect(response).to be_success
        expect(response.payload[:alert]).to eq(alert)
      end

      it_behaves_like 'adds a system note'

      context 'with unknown status' do
        let(:new_status) { :unknown_status }

        it_behaves_like 'error response', 'Invalid status'
      end

      context 'with resolving status' do
        let(:new_status) { :resolved }

        it 'changes the status' do
          expect { response }.to change { alert.resolved? }.to(true)
        end

        it "resolves the current user's related todos" do
          todo = create(:todo, :pending, target: alert, user: current_user, project: alert.project)

          expect { response }.to change { todo.reload.state }.from('pending').to('done')
        end
      end

      context 'with existing unresolved alert' do
        context 'with fingerprints' do
          let_it_be(:existing_alert) { create(:alert_management_alert, :triggered, fingerprint: alert.fingerprint, project: project) }

          it 'does not query for existing alerts' do
            expect(::AlertManagement::Alert).not_to receive(:find_unresolved_alert)

            response
          end

          context 'when status was resolved' do
            let_it_be(:alert) { create(:alert_management_alert, :resolved, :with_fingerprint, project: project) }
            let_it_be(:existing_alert) { create(:alert_management_alert, :triggered, fingerprint: alert.fingerprint, project: project) }

            let(:url) { Gitlab::Routing.url_helpers.details_project_alert_management_path(project, existing_alert) }
            let(:link) { ActionController::Base.helpers.link_to(_('alert'), url) }
            let(:message) do
              "An #{link} with the same fingerprint is already open. " \
              'To change the status of this alert, resolve the linked alert.'
            end

            it_behaves_like 'does not add a todo'
            it_behaves_like 'does not add a system note'

            it 'has an informative message' do
              expect(response).to be_error
              expect(response.message).to eq(message)
            end
          end
        end

        context 'without fingerprints' do
          let_it_be(:existing_alert) { create(:alert_management_alert, :triggered, fingerprint: alert.fingerprint, project: project) }

          it 'successfully changes the status' do
            expect { response }.to change { alert.acknowledged? }.to(true)
            expect(response).to be_success
            expect(response.payload[:alert]).to eq(alert)
          end

          it_behaves_like 'adds a system note'
        end
      end

      context 'two existing closed alerts' do
        let_it_be(:alert) { create(:alert_management_alert, :resolved, :with_fingerprint, project: project) }
        let_it_be(:existing_alert) { create(:alert_management_alert, :resolved, fingerprint: alert.fingerprint, project: project) }

        it 'successfully changes the status' do
          expect { response }.to change { alert.acknowledged? }.to(true)
          expect(response).to be_success
          expect(response.payload[:alert]).to eq(alert)
        end

        it_behaves_like 'adds a system note'
      end
    end
  end
end
