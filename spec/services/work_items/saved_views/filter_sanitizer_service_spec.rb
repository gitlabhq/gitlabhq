# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::FilterSanitizerService, feature_category: :portfolio_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:namespace) { group }
  let(:filter_data) { {} }

  subject(:service) do
    described_class.new(filter_data: filter_data, namespace: namespace, current_user: current_user)
  end

  describe '#execute' do
    subject(:result) { service.execute }

    it 'returns a successful response' do
      expect(result).to be_success
      expect(result.payload).to include(filters: {}, warnings: [])
    end

    describe 'static filters' do
      let(:filter_data) { { state: 'opened', confidential: true, issue_types: ['ISSUE'] } }

      it 'passes through static filters unchanged' do
        expect(result.payload[:filters]).to include(state: 'opened', confidential: true, types: ['ISSUE'])
        expect(result.payload[:warnings]).to be_empty
      end

      context 'with negated static filters' do
        let(:filter_data) { { not: { issue_types: ['TASK'] } } }

        it 'passes through negated static filters unchanged' do
          expect(result.payload[:filters][:not]).to include(types: ['TASK'])
          expect(result.payload[:warnings]).to be_empty
        end
      end
    end

    describe 'assignee validation' do
      let_it_be(:assignee1) { create(:user) }
      let_it_be(:assignee2) { create(:user) }

      context 'with valid assignee IDs' do
        let(:filter_data) { { assignee_ids: [assignee1.id, assignee2.id] } }

        it 'converts IDs to usernames' do
          expect(result.payload[:filters][:assignee_usernames]).to contain_exactly(
            assignee1.username, assignee2.username
          )
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted assignee' do
        let(:filter_data) { { assignee_ids: [assignee1.id, non_existing_record_id] } }

        it 'returns found usernames and warning for missing' do
          expect(result.payload[:filters][:assignee_usernames]).to eq([assignee1.username])
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :assignee_usernames, message: '1 assignee(s) not found' }
          )
        end
      end

      context 'with all deleted assignees' do
        let(:filter_data) { { assignee_ids: [non_existing_record_id] } }

        it 'returns no usernames and warning' do
          expect(result.payload[:filters][:assignee_usernames]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :assignee_usernames, message: '1 assignee(s) not found' }
          )
        end
      end

      context 'with negated assignee' do
        let(:filter_data) { { not: { assignee_ids: [assignee1.id] } } }

        it 'converts negated IDs to usernames' do
          expect(result.payload[:filters][:not][:assignee_usernames]).to eq([assignee1.username])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with negated deleted assignee' do
        let(:filter_data) { { not: { assignee_ids: [non_existing_record_id] } } }

        it 'returns warning for missing negated assignee' do
          expect(result.payload[:filters][:not][:assignee_usernames]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :not_assignee_usernames, message: '1 assignee(s) not found' }
          )
        end
      end

      context 'with OR assignee' do
        let(:filter_data) { { or: { assignee_ids: [assignee1.id, assignee2.id] } } }

        it 'converts OR IDs to usernames' do
          expect(result.payload[:filters][:or][:assignee_usernames]).to contain_exactly(
            assignee1.username, assignee2.username
          )
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with OR assignee containing all deleted users' do
        let(:filter_data) { { or: { assignee_ids: [non_existing_record_id] } } }

        it 'returns warning and no assignees' do
          expect(result.payload[:filters][:or]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :or_assignee_usernames, message: '1 assignee(s) not found' }
          )
        end
      end

      context 'with OR assignee containing mix of valid and deleted users' do
        let(:filter_data) { { or: { assignee_ids: [assignee1.id, non_existing_record_id] } } }

        it 'returns found assignees and warning for missing' do
          expect(result.payload[:filters][:or][:assignee_usernames]).to eq([assignee1.username])
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :or_assignee_usernames, message: '1 assignee(s) not found' }
          )
        end
      end
    end

    describe 'author validation' do
      let_it_be(:author) { create(:user) }

      context 'with single valid author ID' do
        let(:filter_data) { { author_ids: [author.id] } }

        it 'converts ID to singular username' do
          expect(result.payload[:filters][:author_username]).to eq(author.username)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with multiple valid author IDs' do
        let_it_be(:author2) { create(:user) }
        let(:filter_data) { { author_ids: [author.id, author2.id] } }

        it 'converts IDs to array of usernames' do
          expect(result.payload[:filters][:author_username]).to contain_exactly(author.username, author2.username)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted author' do
        let(:filter_data) { { author_ids: [non_existing_record_id] } }

        it 'returns warning for missing author' do
          expect(result.payload[:filters][:author_username]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :author_username, message: '1 author(s) not found' }
          )
        end
      end

      context 'with negated author' do
        let(:filter_data) { { not: { author_ids: [author.id] } } }

        it 'converts negated ID to username' do
          expect(result.payload[:filters][:not][:author_username]).to eq([author.username])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with OR author' do
        let_it_be(:author2) { create(:user) }
        let(:filter_data) { { or: { author_ids: [author.id, author2.id] } } }

        it 'converts OR IDs to author_usernames (plural key)' do
          expect(result.payload[:filters][:or][:author_usernames]).to contain_exactly(
            author.username, author2.username
          )
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with OR author containing deleted user' do
        let(:filter_data) { { or: { author_ids: [non_existing_record_id] } } }

        it 'returns warning and no usernames when all authors deleted' do
          expect(result.payload[:filters][:or]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :or_author_usernames, message: '1 author(s) not found' }
          )
        end
      end

      context 'with OR author containing mix of valid and deleted users' do
        let_it_be(:valid_author) { create(:user) }
        let(:filter_data) { { or: { author_ids: [valid_author.id, non_existing_record_id] } } }

        it 'returns found usernames and warning for missing' do
          expect(result.payload[:filters][:or][:author_usernames]).to eq([valid_author.username])
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :or_author_usernames, message: '1 author(s) not found' }
          )
        end
      end
    end

    describe 'label validation' do
      let_it_be(:label1) { create(:group_label, group: group) }
      let_it_be(:label2) { create(:group_label, group: group) }

      context 'with valid label IDs' do
        let(:filter_data) { { label_ids: [label1.id, label2.id] } }

        it 'converts IDs to titles' do
          expect(result.payload[:filters][:label_name]).to contain_exactly(label1.title, label2.title)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted label' do
        let(:filter_data) { { label_ids: [label1.id, non_existing_record_id] } }

        it 'returns found titles and warning for missing' do
          expect(result.payload[:filters][:label_name]).to eq([label1.title])
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :label_name, message: '1 label(s) not found' }
          )
        end
      end

      context 'with negated labels' do
        let(:filter_data) { { not: { label_ids: [label1.id] } } }

        it 'converts negated IDs to titles' do
          expect(result.payload[:filters][:not][:label_name]).to eq([label1.title])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with OR labels' do
        let(:filter_data) { { or: { label_ids: [label1.id, label2.id] } } }

        it 'converts OR IDs to label_names (plural key)' do
          expect(result.payload[:filters][:or][:label_names]).to contain_exactly(label1.title, label2.title)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with duplicate label IDs' do
        let(:filter_data) { { label_ids: [label1.id, label1.id] } }

        it 'returns unique titles' do
          expect(result.payload[:filters][:label_name]).to eq([label1.title])
        end
      end

      context 'with OR labels containing deleted label' do
        let(:filter_data) { { or: { label_ids: [non_existing_record_id] } } }

        it 'returns warning and no labels when all labels deleted' do
          expect(result.payload[:filters][:or]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :or_label_names, message: '1 label(s) not found' }
          )
        end
      end

      context 'with OR labels containing mix of valid and deleted labels' do
        let(:filter_data) { { or: { label_ids: [label1.id, non_existing_record_id] } } }

        it 'returns found labels and warning for missing' do
          expect(result.payload[:filters][:or][:label_names]).to eq([label1.title])
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :or_label_names, message: '1 label(s) not found' }
          )
        end
      end
    end

    describe 'milestone validation' do
      let_it_be(:milestone) { create(:milestone, group: group) }

      context 'with valid milestone ID' do
        let(:filter_data) { { milestone_ids: [milestone.id] } }

        it 'converts ID to title' do
          expect(result.payload[:filters][:milestone_title]).to eq([milestone.title])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted milestone' do
        let(:filter_data) { { milestone_ids: [non_existing_record_id] } }

        it 'returns warning for missing milestone' do
          expect(result.payload[:filters][:milestone_title]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :milestone_title, message: '1 milestone(s) not found' }
          )
        end
      end

      context 'with negated milestone' do
        let(:filter_data) { { not: { milestone_ids: [milestone.id] } } }

        it 'converts negated ID to title' do
          expect(result.payload[:filters][:not][:milestone_title]).to eq([milestone.title])
          expect(result.payload[:warnings]).to be_empty
        end
      end
    end

    describe 'release validation' do
      let_it_be(:release) { create(:release, project: project) }
      let(:namespace) { project.project_namespace }

      context 'with valid release ID' do
        let(:filter_data) { { release_ids: [release.id] } }

        it 'converts ID to tag' do
          expect(result.payload[:filters][:release_tag]).to eq([release.tag])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted release' do
        let(:filter_data) { { release_ids: [non_existing_record_id] } }

        it 'returns warning for missing release' do
          expect(result.payload[:filters][:release_tag]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :release_tag, message: '1 release(s) not found' }
          )
        end
      end
    end

    describe 'hierarchy filters validation' do
      let_it_be(:parent_work_item) { create(:work_item, :epic, namespace: group) }

      context 'with valid parent work item IDs' do
        let(:filter_data) { { hierarchy_filters: { work_item_parent_ids: [parent_work_item.id] } } }

        it 'converts IDs to global IDs' do
          expected_gid = Gitlab::GlobalId.build(parent_work_item, id: parent_work_item.id).to_s

          expect(result.payload[:filters][:hierarchy_filters][:parent_ids]).to eq([expected_gid])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted parent work item' do
        let(:filter_data) { { hierarchy_filters: { work_item_parent_ids: [non_existing_record_id] } } }

        it 'returns warning for missing parent' do
          expect(result.payload[:filters][:hierarchy_filters]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :parent_ids, message: '1 parent work item(s) not found' }
          )
        end
      end

      context 'with parent_wildcard_id' do
        let(:filter_data) { { hierarchy_filters: { parent_wildcard_id: 'NONE' } } }

        it 'passes through wildcard unchanged' do
          expect(result.payload[:filters][:hierarchy_filters][:parent_wildcard_id]).to eq('NONE')
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with include_descendant_work_items' do
        let(:filter_data) { { hierarchy_filters: { include_descendant_work_items: true } } }

        it 'passes through include_descendant_work_items unchanged' do
          expect(result.payload[:filters][:hierarchy_filters][:include_descendant_work_items]).to be true
          expect(result.payload[:warnings]).to be_empty
        end
      end
    end

    describe 'CRM validation' do
      context 'with valid CRM contact' do
        let_it_be(:crm_contact) { create(:contact, group: group) }
        let_it_be(:issue) { create(:issue, project: project) }
        let_it_be(:issue_contact) { create(:issue_customer_relations_contact, issue: issue, contact: crm_contact) }

        let(:filter_data) { { crm_contact_id: crm_contact.id } }

        it 'passes through CRM contact ID' do
          expect(result.payload[:filters][:crm_contact_id]).to eq(crm_contact.id)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with invalid CRM contact' do
        let(:filter_data) { { crm_contact_id: non_existing_record_id } }

        it 'returns warning for missing CRM contact' do
          expect(result.payload[:filters][:crm_contact_id]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :crm_contact_id, message: 'CRM contact not found' }
          )
        end
      end

      context 'with valid CRM organization' do
        let_it_be(:crm_organization) { create(:crm_organization, group: group) }
        let_it_be(:crm_contact) { create(:contact, group: group, organization: crm_organization) }

        let(:filter_data) { { crm_organization_id: crm_organization.id } }

        it 'passes through CRM organization ID' do
          expect(result.payload[:filters][:crm_organization_id]).to eq(crm_organization.id)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with invalid CRM organization' do
        let(:filter_data) { { crm_organization_id: non_existing_record_id } }

        it 'returns warning for missing CRM organization' do
          expect(result.payload[:filters][:crm_organization_id]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :crm_organization_id, message: 'CRM organization not found' }
          )
        end
      end
    end

    describe 'full_path validation' do
      context 'with valid group namespace_id' do
        let(:filter_data) { { namespace_id: group.id } }

        it 'converts namespace_id to full_path' do
          expect(result.payload[:filters][:full_path]).to eq(group.full_path)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with valid project namespace_id' do
        let(:filter_data) { { namespace_id: project.project_namespace_id } }

        it 'converts project namespace_id to full_path' do
          expect(result.payload[:filters][:full_path]).to eq(project.full_path)
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with invalid namespace_id' do
        let(:filter_data) { { namespace_id: non_existing_record_id } }

        it 'returns warning for missing routable' do
          expect(result.payload[:filters][:full_path]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :full_path, message: 'Group / Project not found' }
          )
        end
      end
    end

    describe 'combined filters' do
      let_it_be(:assignee) { create(:user) }
      let_it_be(:label) { create(:group_label, group: group) }

      let(:filter_data) do
        {
          state: 'opened',
          assignee_ids: [assignee.id, non_existing_record_id],
          label_ids: [label.id],
          not: { label_ids: [non_existing_record_id] }
        }
      end

      it 'processes all filters and collects warnings' do
        expect(result.payload[:filters]).to include(
          state: 'opened',
          assignee_usernames: [assignee.username],
          label_name: [label.title]
        )
        expect(result.payload[:warnings]).to contain_exactly(
          { field: :assignee_usernames, message: '1 assignee(s) not found' },
          { field: :not_label_name, message: '1 label(s) not found' }
        )
      end
    end

    describe 'negated parent_ids validation' do
      let_it_be(:parent_work_item) { create(:work_item, :epic, namespace: group) }

      context 'with valid negated parent IDs' do
        let(:filter_data) { { not: { parent_ids: [parent_work_item.id] } } }

        it 'converts IDs to global IDs' do
          expected_gid = Gitlab::GlobalId.build(parent_work_item, id: parent_work_item.id).to_s

          expect(result.payload[:filters][:not][:parent_ids]).to eq([expected_gid])
          expect(result.payload[:warnings]).to be_empty
        end
      end

      context 'with deleted negated parent work item' do
        let(:filter_data) { { not: { parent_ids: [non_existing_record_id] } } }

        it 'returns warning for missing parent' do
          expect(result.payload[:filters][:not][:parent_ids]).to be_nil
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :not_parent_ids, message: '1 parent work item(s) not found' }
          )
        end
      end

      context 'with mixed valid and deleted negated parent IDs' do
        let(:filter_data) { { not: { parent_ids: [parent_work_item.id, non_existing_record_id] } } }

        it 'returns found IDs and warning for missing' do
          expected_gid = Gitlab::GlobalId.build(parent_work_item, id: parent_work_item.id).to_s

          expect(result.payload[:filters][:not][:parent_ids]).to eq([expected_gid])
          expect(result.payload[:warnings]).to contain_exactly(
            { field: :not_parent_ids, message: '1 parent work item(s) not found' }
          )
        end
      end
    end

    describe 'error handling' do
      let_it_be(:assignee1) { create(:user) }

      context 'when an ArgumentError is raised during validation' do
        let(:filter_data) { { assignee_ids: [assignee1.id] } }

        before do
          allow(service).to receive(:validate_assignee).and_raise(ArgumentError.new('Example Error'))
        end

        it 'returns an error response' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Example Error')
        end
      end
    end
  end
end
