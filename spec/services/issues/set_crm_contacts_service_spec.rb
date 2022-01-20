# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::SetCrmContactsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :crm_enabled) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:contacts) { create_list(:contact, 4, group: group) }

  let(:issue) { create(:issue, project: project) }
  let(:does_not_exist_or_no_permission) { "The resource that you are attempting to access does not exist or you don't have permission to perform this action" }

  before do
    create(:issue_customer_relations_contact, issue: issue, contact: contacts[0])
    create(:issue_customer_relations_contact, issue: issue, contact: contacts[1])
  end

  subject(:set_crm_contacts) do
    described_class.new(project: project, current_user: user, params: params).execute(issue)
  end

  describe '#execute' do
    context 'when the user has no permission' do
      let(:params) { { replace_ids: [contacts[1].id, contacts[2].id] } }

      it 'returns expected error response' do
        response = set_crm_contacts

        expect(response).to be_error
        expect(response.message).to eq('You have insufficient permissions to set customer relations contacts for this issue')
      end
    end

    context 'when user has permission' do
      before do
        group.add_reporter(user)
      end

      context 'when the contact does not exist' do
        let(:params) { { replace_ids: [non_existing_record_id] } }

        it 'returns expected error response' do
          response = set_crm_contacts

          expect(response).to be_error
          expect(response.message).to eq("Issue customer relations contacts #{non_existing_record_id}: #{does_not_exist_or_no_permission}")
        end
      end

      context 'when the contact belongs to a different group' do
        let(:group2) { create(:group) }
        let(:contact) { create(:contact, group: group2) }
        let(:params) { { replace_ids: [contact.id] } }

        before do
          group2.add_reporter(user)
        end

        it 'returns expected error response' do
          response = set_crm_contacts

          expect(response).to be_error
          expect(response.message).to eq("Issue customer relations contacts #{contact.id}: #{does_not_exist_or_no_permission}")
        end
      end

      context 'replace' do
        let(:params) { { replace_ids: [contacts[1].id, contacts[2].id] } }

        it 'updates the issue with correct contacts' do
          response = set_crm_contacts

          expect(response).to be_success
          expect(issue.customer_relations_contacts).to match_array([contacts[1], contacts[2]])
        end
      end

      context 'add' do
        let(:params) { { add_ids: [contacts[3].id] } }

        it 'updates the issue with correct contacts' do
          response = set_crm_contacts

          expect(response).to be_success
          expect(issue.customer_relations_contacts).to match_array([contacts[0], contacts[1], contacts[3]])
        end
      end

      context 'add by email' do
        let(:params) { { add_emails: [contacts[3].email] } }

        it 'updates the issue with correct contacts' do
          response = set_crm_contacts

          expect(response).to be_success
          expect(issue.customer_relations_contacts).to match_array([contacts[0], contacts[1], contacts[3]])
        end
      end

      context 'remove' do
        let(:params) { { remove_ids: [contacts[0].id] } }

        it 'updates the issue with correct contacts' do
          response = set_crm_contacts

          expect(response).to be_success
          expect(issue.customer_relations_contacts).to match_array([contacts[1]])
        end
      end

      context 'remove by email' do
        let(:params) { { remove_emails: [contacts[0].email] } }

        it 'updates the issue with correct contacts' do
          response = set_crm_contacts

          expect(response).to be_success
          expect(issue.customer_relations_contacts).to match_array([contacts[1]])
        end
      end

      context 'when attempting to add more than 6' do
        let(:id) { contacts[0].id }
        let(:params) { { add_ids: [id, id, id, id, id, id, id] } }

        it 'returns expected error message' do
          response = set_crm_contacts

          expect(response).to be_error
          expect(response.message).to eq('You can only add up to 6 contacts at one time')
        end
      end

      context 'when trying to remove non-existent contact' do
        let(:params) { { remove_ids: [non_existing_record_id] } }

        it 'returns expected error message' do
          response = set_crm_contacts

          expect(response).to be_success
          expect(response.message).to be_nil
        end
      end

      context 'when combining params' do
        let(:error_invalid_params) { 'You cannot combine replace_ids with add_ids or remove_ids' }

        context 'add and remove' do
          let(:params) { { remove_ids: [contacts[1].id], add_ids: [contacts[3].id] } }

          it 'updates the issue with correct contacts' do
            response = set_crm_contacts

            expect(response).to be_success
            expect(issue.customer_relations_contacts).to match_array([contacts[0], contacts[3]])
          end
        end

        context 'replace and remove' do
          let(:params) { { replace_ids: [contacts[3].id], remove_ids: [contacts[0].id] } }

          it 'returns expected error response' do
            response = set_crm_contacts

            expect(response).to be_error
            expect(response.message).to eq(error_invalid_params)
          end
        end

        context 'replace and add' do
          let(:params) { { replace_ids: [contacts[3].id], add_ids: [contacts[1].id] } }

          it 'returns expected error response' do
            response = set_crm_contacts

            expect(response).to be_error
            expect(response.message).to eq(error_invalid_params)
          end
        end
      end

      context 'when trying to add an existing issue contact' do
        let(:params) { { add_ids: [contacts[0].id] } }

        it 'does not return an error' do
          response = set_crm_contacts

          expect(response).to be_success
        end
      end

      context 'when trying to add the same contact twice' do
        let(:params) { { add_ids: [contacts[3].id, contacts[3].id] } }

        it 'does not return an error' do
          response = set_crm_contacts

          expect(response).to be_success
        end
      end

      context 'when trying to remove a contact not attached to the issue' do
        let(:params) { { remove_ids: [contacts[3].id] } }

        it 'does not return an error' do
          response = set_crm_contacts

          expect(response).to be_success
        end
      end
    end
  end
end
