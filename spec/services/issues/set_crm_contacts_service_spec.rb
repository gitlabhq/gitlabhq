# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::SetCrmContactsService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: create(:group, parent: group)) }
  let_it_be(:contacts) { create_list(:contact, 4, group: group) }
  let_it_be(:issue, reload: true) { create(:issue, project: project) }
  let_it_be(:issue_contact_1) do
    create(:issue_customer_relations_contact, issue: issue, contact: contacts[0]).contact
  end

  let_it_be(:issue_contact_2) do
    create(:issue_customer_relations_contact, issue: issue, contact: contacts[1]).contact
  end

  let(:does_not_exist_or_no_permission) { "The resource that you are attempting to access does not exist or you don't have permission to perform this action" }

  subject(:set_crm_contacts) do
    described_class.new(container: project, current_user: user, params: params).execute(issue)
  end

  describe '#execute' do
    shared_examples 'setting contacts' do
      it 'updates the issue with correct contacts' do
        response = set_crm_contacts

        expect(response).to be_success
        expect(issue.customer_relations_contacts).to match_array(expected_contacts)
      end
    end

    shared_examples 'adds system note' do |added_count, removed_count|
      it 'calls SystemNoteService.change_issuable_contacts with correct counts' do
        expect(SystemNoteService)
          .to receive(:change_issuable_contacts)
          .with(issue, project, user, added_count, removed_count)

        set_crm_contacts
      end
    end

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

      context 'but the crm setting is disabled' do
        let(:params) { { replace_ids: [contacts[1].id, contacts[2].id] } }
        let(:subgroup_with_crm_disabled) { create(:group, :crm_disabled, parent: group) }
        let(:project_with_crm_disabled) { create(:project, group: subgroup_with_crm_disabled) }
        let(:issue_with_crm_disabled) { create(:issue, project: project_with_crm_disabled) }

        it 'returns expected error response' do
          response = described_class.new(container: project_with_crm_disabled, current_user: user, params: params).execute(issue_with_crm_disabled)

          expect(response).to be_error
          expect(response.message).to eq('You have insufficient permissions to set customer relations contacts for this issue')
        end
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
        let(:expected_contacts) { [contacts[1], contacts[2]] }

        it_behaves_like 'setting contacts'
        it_behaves_like 'adds system note', 1, 1

        context 'with empty list' do
          let(:params) { { replace_ids: [] } }
          let(:expected_contacts) { [] }

          it_behaves_like 'setting contacts'
          it_behaves_like 'adds system note', 0, 2
        end
      end

      context 'add' do
        let(:added_contact) { contacts[3] }
        let(:params) { { add_ids: [added_contact.id] } }
        let(:expected_contacts) { [issue_contact_1, issue_contact_2, added_contact] }

        it_behaves_like 'setting contacts'
        it_behaves_like 'adds system note', 1, 0
      end

      context 'add by email' do
        let(:added_contact) { contacts[3] }
        let(:expected_contacts) { [issue_contact_1, issue_contact_2, added_contact] }

        context 'with pure emails in params' do
          let(:params) { { add_emails: [contacts[3].email] } }

          it_behaves_like 'setting contacts'
          it_behaves_like 'adds system note', 1, 0
        end

        context 'with autocomplete prefix emails in params' do
          let(:params) { { add_emails: ["[\"contact:\"#{contacts[3].email}\"]"] } }

          it_behaves_like 'setting contacts'
          it_behaves_like 'adds system note', 1, 0
        end
      end

      context 'remove' do
        let(:params) { { remove_ids: [contacts[0].id] } }
        let(:expected_contacts) { [contacts[1]] }

        it_behaves_like 'setting contacts'
        it_behaves_like 'adds system note', 0, 1
      end

      context 'remove by email' do
        let(:expected_contacts) { [contacts[1]] }

        context 'with pure email in params' do
          let(:params) { { remove_emails: [contacts[0].email] } }

          it_behaves_like 'setting contacts'
          it_behaves_like 'adds system note', 0, 1
        end

        context 'with autocomplete prefix and suffix email in params' do
          let(:params) { { remove_emails: ["[contact:#{contacts[0].email}]"] } }

          it_behaves_like 'setting contacts'
          it_behaves_like 'adds system note', 0, 1
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
        let(:expected_contacts) { [contacts[0], contacts[3]] }

        context 'add and remove' do
          context 'with contact ids' do
            let(:params) { { remove_ids: [contacts[1].id], add_ids: [contacts[3].id] } }

            it_behaves_like 'setting contacts'
          end

          context 'with contact emails' do
            let(:params) { { remove_emails: [contacts[1].email], add_emails: ["[\"contact:#{contacts[3].email}]"] } }

            it_behaves_like 'setting contacts'
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

      context 'when setting contacts for a group level work item', if: Gitlab.ee? do
        let(:params) { { add_ids: [contacts[3].id] } }

        before do
          stub_licensed_features(epics: true)
        end

        it 'sets the contacts' do
          work_item = create(:work_item, :epic, namespace: group)

          response = described_class.new(container: work_item.namespace, current_user: user, params: params).execute(work_item)

          expect(response).to be_success
          expect(work_item.customer_relations_contacts).to contain_exactly(contacts[3])
        end

        context 'without group level work item license' do
          before do
            stub_licensed_features(epics: false)
          end

          it 'does not set contacts' do
            work_item = create(:work_item, :epic, namespace: group)

            response = described_class.new(container: work_item.namespace, current_user: user, params: params).execute(work_item)

            expect(response).to be_error
            expect(response.message).to eq('You have insufficient permissions to set customer relations contacts for this issue')
          end
        end
      end
    end
  end
end
