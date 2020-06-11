# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::Alerts::UpdateService do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:alert, reload: true) { create(:alert_management_alert) }
  let_it_be(:project) { alert.project }

  let(:current_user) { user_with_permissions }
  let(:params) { {} }

  let(:service) { described_class.new(alert, current_user, params) }

  before_all do
    project.add_developer(user_with_permissions)
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when user does not have permission to update alerts' do
      let(:current_user) { user_without_permissions }

      it 'results in an error' do
        expect(response).to be_error
        expect(response.message).to eq('You have no permissions')
      end
    end

    context 'when no parameters are included' do
      it 'results in an error' do
        expect(response).to be_error
        expect(response.message).to eq('Please provide attributes to update')
      end
    end

    context 'when an error occures during update' do
      let(:params) { { title: nil } }

      it 'results in an error' do
        expect(response).to be_error
        expect(response.message).to eq("Title can't be blank")
      end
    end

    context 'when a model attribute is included' do
      let(:params) { { title: 'This is an updated alert.' } }

      it 'updates the attribute' do
        original_title = alert.title

        expect { response }.to change { alert.title }.from(original_title).to(params[:title])
        expect(response).to be_success
      end
    end

    context 'when assignees are included' do
      let(:params) { { assignees: [user_with_permissions] } }

      after do
        alert.assignees = []
      end

      it 'assigns the user' do
        expect { response }.to change { alert.reload.assignees }.from([]).to(params[:assignees])
        expect(response).to be_success
      end

      context 'with multiple users included' do
        let(:params) { { assignees: [user_with_permissions, user_without_permissions] } }

        it 'assigns the first permissioned user' do
          expect { response }.to change { alert.reload.assignees }.from([]).to([user_with_permissions])
          expect(response).to be_success
        end
      end
    end
  end
end
