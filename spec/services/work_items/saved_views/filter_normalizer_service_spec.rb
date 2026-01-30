# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::FilterNormalizerService, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:current_user) { create(:user, developer_of: [group, project]) }

  let_it_be(:user1) { create(:user, username: 'alice') }
  let_it_be(:user2) { create(:user, username: 'bob') }

  let_it_be(:group_label) { create(:group_label, group: group, title: 'bug') }
  let_it_be(:project_label) { create(:label, project: project, title: 'feature') }

  let_it_be(:milestone) { create(:milestone, group: subgroup, title: 'v1.0') }
  let_it_be(:project_milestone) { create(:milestone, project: project, title: 'v2.0') }

  let(:container) { project }
  let(:filter_data) { {} }

  subject(:service) { described_class.new(filter_data: filter_data, container: container, current_user: current_user) }

  describe '#execute' do
    context 'with static filters' do
      let(:filter_data) do
        {
          issue_types: %w[ISSUE TASK],
          state: 'opened',
          confidential: true
        }
      end

      it 'preserves static filters unchanged' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload).to include(
          issue_types: %w[ISSUE TASK],
          state: 'opened',
          confidential: true
        )
      end
    end

    context 'with negated static filters' do
      let(:filter_data) { { not: { issue_types: %w[EPIC] } } }

      it 'normalizes negated filters' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:not]).to include(
          issue_types: %w[EPIC]
        )
      end
    end

    context 'with assignee usernames' do
      let(:filter_data) { { assignee_usernames: %w[alice bob] } }

      it 'converts usernames to user IDs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:assignee_ids]).to match_array([user1.id, user2.id])
      end

      context 'with negated assignees' do
        let(:filter_data) { { not: { assignee_usernames: ['alice'] } } }

        it 'converts negated usernames to user IDs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload.dig(:not, :assignee_ids)).to eq([user1.id])
        end
      end

      context 'with unioned assignees' do
        let(:filter_data) { { or: { assignee_usernames: ['bob'] } } }

        it 'converts unioned usernames to user IDs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload.dig(:or, :assignee_ids)).to eq([user2.id])
        end
      end
    end

    context 'with author username' do
      let(:filter_data) { { author_username: 'alice' } }

      it 'converts username to user ID' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:author_ids]).to eq([user1.id])
      end

      context 'with array of usernames' do
        let(:filter_data) { { author_username: %w[alice bob] } }

        it 'converts all usernames to user IDs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:author_ids]).to match_array([user1.id, user2.id])
        end
      end

      context 'with unioned author_usernames' do
        let(:filter_data) { { or: { author_usernames: %w[alice bob] } } }

        it 'converts unioned usernames to user IDs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload.dig(:or, :author_ids)).to match_array([user1.id, user2.id])
        end
      end

      context 'with negated author username' do
        let(:filter_data) { { not: { author_username: 'alice' } } }

        it 'converts negated username to user ID' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload.dig(:not, :author_ids)).to eq([user1.id])
        end
      end
    end

    context 'with label names' do
      let(:filter_data) { { label_name: ['bug'] } }

      it 'converts label names to label IDs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:label_ids]).to eq([group_label.id])
      end

      context 'with project labels' do
        let(:filter_data) { { label_name: ['feature'] } }

        it 'finds project labels' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:label_ids]).to eq([project_label.id])
        end
      end

      context 'with unioned label_names' do
        let(:filter_data) { { or: { label_names: %w[bug feature] } } }

        it 'converts unioned label names to label IDs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload.dig(:or, :label_ids)).to match_array([group_label.id, project_label.id])
        end
      end

      context 'with negated label names' do
        let(:filter_data) { { not: { label_name: ['bug'] } } }

        it 'converts negated label names to label IDs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload.dig(:not, :label_ids)).to eq([group_label.id])
        end
      end

      context 'when project has no parent group' do
        let_it_be(:root_project) { create(:project, developers: [current_user]) }
        let_it_be(:root_project_label) { create(:label, project: root_project, title: 'root-label') }
        let(:container) { root_project }
        let(:filter_data) { { label_name: ['root-label'] } }

        it 'finds labels in the root project' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:label_ids]).to eq([root_project_label.id])
        end
      end
    end

    context 'with milestone title' do
      let(:filter_data) { { milestone_title: ['v1.0'] } }

      it 'converts milestone titles to milestone IDs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:milestone_ids]).to eq([milestone.id])
      end

      context 'with project milestone' do
        let(:filter_data) { { milestone_title: ['v2.0'] } }

        it 'finds project milestones' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:milestone_ids]).to eq([project_milestone.id])
        end
      end

      context 'when container is a group' do
        let(:container) { group }
        let(:filter_data) { { milestone_title: ['v1.0'] } }

        it 'finds milestones in group hierarchy' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:milestone_ids]).to eq([milestone.id])
        end
      end
    end

    context 'with release tag' do
      let_it_be(:release) { create(:release, project: project, tag: 'v1.0.0') }
      let(:filter_data) { { release_tag: ['v1.0.0'] } }

      it 'converts release tags to release IDs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:release_ids]).to eq([release.id])
      end

      context 'when container is a group' do
        let(:container) { group }
        let(:filter_data) { { release_tag: ['v1.0.0'] } }

        it 'does not normalize release tags' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).not_to have_key(:release_ids)
        end
      end
    end

    context 'with CRM contact ID' do
      let(:filter_data) { { crm_contact_id: 123 } }

      it 'preserves CRM contact ID' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:crm_contact_id]).to eq(123)
      end
    end

    context 'with CRM organization ID' do
      let(:filter_data) { { crm_organization_id: 456 } }

      it 'preserves CRM organization ID' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:crm_organization_id]).to eq(456)
      end
    end

    context 'with full_path' do
      context 'when routable is a group' do
        let(:filter_data) { { full_path: group.full_path } }

        it 'converts to namespace_id' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:namespace_id]).to eq(group.id)
        end
      end

      context 'when routable is a project' do
        let(:filter_data) { { full_path: project.full_path } }

        it 'converts to project_namespace_id' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:namespace_id]).to eq(project.project_namespace_id)
        end

        context 'when the user cannot read the project' do
          let_it_be(:private_project) { create(:project) }
          let(:filter_data) { { full_path: private_project.full_path } }

          it 'does not normalize the full_path' do
            result = service.execute

            expect(result).to be_success
            expect(result.payload).not_to have_key(:namespace_id)
          end

          it 'removes the full_path filter' do
            result = service.execute

            expect(result).to be_success
            expect(result.payload).not_to have_key(:full_path)
          end
        end
      end

      context 'when user does not have access to the routable' do
        let_it_be(:private_group) { create(:group, :private) }
        let(:filter_data) { { full_path: private_group.full_path } }

        it 'does not set namespace_id' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).not_to have_key(:namespace_id)
        end
      end

      context 'when user has access to the routable' do
        let_it_be(:accessible_group) { create(:group, :private, developers: [current_user]) }
        let(:filter_data) { { full_path: accessible_group.full_path } }

        it 'sets namespace_id' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:namespace_id]).to eq(accessible_group.id)
        end
      end

      context 'when routable is a user namespace' do
        let_it_be(:user_namespace) { create(:user_namespace) }
        let(:filter_data) { { full_path: user_namespace.full_path } }

        it 'does not set namespace_id' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).not_to have_key(:namespace_id)
        end
      end

      context 'when routable does not exist' do
        let(:filter_data) { { full_path: 'nonexistent/path' } }

        it 'does not set namespace_id' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).not_to have_key(:namespace_id)
        end
      end
    end

    context 'with hierarchy filters' do
      let(:filter_data) do
        {
          hierarchy_filters: {
            parent_ids: [1, 2, 3],
            parent_wildcard_id: 'NONE',
            include_descendant_work_items: true
          }
        }
      end

      it 'normalizes hierarchy filters' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:hierarchy_filters]).to eq(
          work_item_parent_ids: [1, 2, 3],
          parent_wildcard_id: 'NONE',
          include_descendant_work_items: true
        )
      end

      context 'with partial hierarchy filters' do
        let(:filter_data) { { hierarchy_filters: { parent_ids: [1, 2] } } }

        it 'normalizes only provided filters' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:hierarchy_filters]).to eq(work_item_parent_ids: [1, 2])
        end
      end

      context 'with empty hierarchy filters' do
        let(:filter_data) { { hierarchy_filters: {} } }

        it 'does not include hierarchy_filters key' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload).not_to have_key(:hierarchy_filters)
        end
      end
    end

    context 'with group container' do
      let(:container) { group }
      let(:filter_data) { { label_name: ['bug'] } }

      it 'finds labels in group hierarchy' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:label_ids]).to eq([group_label.id])
      end
    end

    context 'with complex filters' do
      let(:filter_data) do
        {
          issue_types: ['ISSUE'],
          state: 'opened',
          assignee_usernames: ['alice'],
          author_username: 'bob',
          label_name: ['bug'],
          milestone_title: ['v1.0'],
          not: {
            issue_types: ['EPIC'],
            assignee_usernames: ['bob']
          },
          or: {
            assignee_usernames: ['alice'],
            label_names: ['feature']
          }
        }
      end

      it 'normalizes all filters correctly' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload).to include(
          issue_types: ['ISSUE'],
          state: 'opened',
          assignee_ids: [user1.id],
          author_ids: [user2.id],
          label_ids: [group_label.id],
          milestone_ids: [milestone.id]
        )

        expect(result.payload[:not]).to include(
          issue_types: ['EPIC'],
          assignee_ids: [user2.id]
        )
        expect(result.payload[:or]).to include(
          assignee_ids: [user1.id],
          label_ids: [project_label.id]
        )
      end
    end

    context 'with invalid normalization configuration' do
      before do
        # Needed to avoid early return
        service.instance_variable_set(:@filters, { test_key: 'value' })
      end

      it 'raises an error for unknown method' do
        expect do
          service.send(:normalize_attribute, :test_key, :test_output, method: :unknown_method)
        end.to raise_error(ArgumentError, /Unknown normalization method/)
      end

      it 'raises an error when neither method nor block are provided' do
        expect do
          service.send(:normalize_attribute, :test_key, :test_output)
        end.to raise_error(ArgumentError, /Must provide either method: or a block/)
      end
    end

    context 'when an ArgumentError is raised during normalization' do
      let(:filter_data) { { assignee_usernames: ['alice'] } }

      before do
        allow(service).to receive(:normalize_usernames).and_raise(ArgumentError.new('Example Error'))
      end

      it 'returns an error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Example Error')
      end
    end

    context 'with negated parent_ids' do
      let(:filter_data) { { not: { parent_ids: ['gid://gitlab/WorkItem/1', 'gid://gitlab/WorkItem/2'] } } }

      it 'normalizes negated parent_ids' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload.dig(:not,
          :parent_ids)).to match_array(['gid://gitlab/WorkItem/1', 'gid://gitlab/WorkItem/2'])
      end
    end
  end
end
