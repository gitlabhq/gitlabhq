# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::CrmContacts, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, group: create(:group)) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:target_work_item) { create(:work_item, project: project) }
  let_it_be(:issue_contact1) { create(:issue_customer_relations_contact, :for_issue, issue: work_item) }
  let_it_be(:issue_contact2) { create(:issue_customer_relations_contact, :for_issue, issue: work_item) }
  let(:params) { {} }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_save_commit' do
    context 'when target work item has crm_contacts widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:crm_contacts).and_return(true)
      end

      context "when target work item namespace have same crm_group" do
        it 'copies the contacts from work_item to target_work_item' do
          crm_contacts = work_item.customer_relations_contacts

          callback.after_save_commit

          expect(target_work_item.reload.customer_relations_contacts).to match_array(crm_contacts)
        end

        context "when the operation is move" do
          let(:params) { { operation: :move } }

          it "keeps the created_at and updated_at values of the issue_customer_relations_contacts" do
            callback.after_save_commit

            target_work_item.issue_customer_relations_contacts.each do |target_issue_contact|
              word_item_contact = work_item.issue_customer_relations_contacts
                .find_by(contact_id: target_issue_contact.contact_id)

              expect(target_issue_contact.created_at).to eq(word_item_contact.created_at)
              expect(target_issue_contact.updated_at).to eq(word_item_contact.updated_at)
            end
          end
        end

        context "when the operation is clone" do
          let(:params) { { operation: :clone } }

          it "clones the crm contacts" do
            crm_contacts = work_item.customer_relations_contacts

            callback.after_save_commit

            expect(target_work_item.reload.customer_relations_contacts).to match_array(crm_contacts)
          end
        end
      end

      context "when target work item namespace does not have same crm_group" do
        let_it_be(:target_work_item) { create(:work_item, project: create(:project)) }

        it 'does not copy crm_contacts' do
          expect(work_item.customer_relations_contacts).not_to be_empty

          callback.after_save_commit

          expect(target_work_item.reload.customer_relations_contacts).to be_empty
        end

        it "creates a note with removed contacts quote", :aggregate_failures do
          expect(target_work_item.reload.notes).to be_empty

          callback.after_save_commit

          note = target_work_item.notes.first.note

          expect(target_work_item.reload.notes).not_to be_empty
          expect(note).to include("removed 2 contacts")
        end
      end
    end

    context 'when target work item does not have crm_contacts widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:crm_contacts).and_return(false)
      end

      it 'does not copy crm_contacts' do
        expect(work_item.customer_relations_contacts).not_to be_empty

        callback.after_save_commit

        expect(target_work_item.reload.customer_relations_contacts).to be_empty
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'clears the crm_contacts from the original work item' do
      expect(work_item.customer_relations_contacts).not_to be_empty

      callback.post_move_cleanup

      expect(work_item.reload.customer_relations_contacts).to be_empty
    end
  end
end
