# frozen_string_literal: true

RSpec.shared_examples 'work item supports assignee widget updates via quick actions' do
  let_it_be(:developer) { create(:user, developer_of: project) }

  context 'when assigning a user' do
    let(:body) { "/assign @#{developer.username}" }

    it 'updates the work item assignee' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        noteable.reload
      end.to change { noteable.assignee_ids }.from([]).to([developer.id])

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  context 'when unassigning a user' do
    let(:body) { "/unassign @#{developer.username}" }

    before do
      noteable.update!(assignee_ids: [developer.id])
    end

    it 'updates the work item assignee' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        noteable.reload
      end.to change { noteable.assignee_ids }.from([developer.id]).to([])

      expect(response).to have_gitlab_http_status(:success)
    end
  end
end

RSpec.shared_examples 'work item does not support assignee widget updates via quick actions' do
  let(:developer) { create(:user, developer_of: project) }
  let(:body) { "Updating assignee.\n/assign @#{developer.username}" }

  before do
    WorkItems::Type.default_by_type(:task).widget_definitions
      .find_by_widget_type(:assignees).update!(disabled: true)
  end

  it 'ignores the quick action' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.not_to change { noteable.assignee_ids }
  end
end

RSpec.shared_examples 'work item supports labels widget updates via quick actions' do
  shared_examples 'work item labels are updated' do
    it do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        noteable.reload
      end.to change { noteable.labels.count }.to(expected_labels.count)

      expect(noteable.labels).to match_array(expected_labels)
    end
  end

  let_it_be(:existing_label) { create(:label, project: project) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }

  let(:add_label_ids) { [] }
  let(:remove_label_ids) { [] }

  before do
    noteable.update!(labels: [existing_label])
  end

  context 'when only removing labels' do
    let(:remove_label_ids) { [existing_label.to_gid.to_s] }
    let(:expected_labels) { [] }
    let(:body) { "/remove_label ~\"#{existing_label.name}\"" }

    it_behaves_like 'work item labels are updated'
  end

  context 'when only adding labels' do
    let(:add_label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }
    let(:expected_labels) { [label1, label2, existing_label] }
    let(:body) { "/labels ~\"#{label1.name}\" ~\"#{label2.name}\"" }

    it_behaves_like 'work item labels are updated'
  end

  context 'when adding and removing labels' do
    let(:remove_label_ids) { [existing_label.to_gid.to_s] }
    let(:add_label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }
    let(:expected_labels) { [label1, label2] }
    let(:body) { "/label ~\"#{label1.name}\" ~\"#{label2.name}\"\n/remove_label ~\"#{existing_label.name}\"" }

    it_behaves_like 'work item labels are updated'
  end
end

RSpec.shared_examples 'work item does not support labels widget updates via quick actions' do
  let(:label1) { create(:label, project: project) }
  let(:body) { "Updating labels.\n/labels ~\"#{label1.name}\"" }

  before do
    WorkItems::Type.default_by_type(:task).widget_definitions
      .find_by_widget_type(:labels).update!(disabled: true)
  end

  it 'ignores the quick action' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.not_to change { noteable.labels.count }

    expect(noteable.labels).to be_empty
  end
end

RSpec.shared_examples 'work item supports start and due date widget updates via quick actions' do
  let(:due_date) { Date.today }
  let(:body) { "/remove_due_date" }

  before do
    noteable.update!(due_date: due_date)
  end

  it 'updates start and due date' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.to not_change(noteable, :start_date).and(
      change { noteable.due_date }.from(due_date).to(nil)
    )
  end
end

RSpec.shared_examples 'work item does not support start and due date widget updates via quick actions' do
  let(:body) { "Updating due date.\n/due today" }

  before do
    WorkItems::Type.default_by_type(:task).widget_definitions
      .find_by_widget_type(:start_and_due_date).update!(disabled: true)
  end

  it 'ignores the quick action' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.not_to change { noteable.due_date }
  end
end

RSpec.shared_examples 'work item supports type change via quick actions' do
  let_it_be(:assignee) { create(:user) }
  let_it_be(:task_type) { WorkItems::Type.default_by_type(:task) }

  let(:body) { "Updating type.\n/type issue" }

  before do
    noteable.update!(work_item_type: task_type)
  end

  shared_examples 'a quick command that changes type' do
    it 'updates type' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        noteable.reload
      end.to change { noteable.work_item_type.base_type }.from('task').to('issue')

      expect(response).to have_gitlab_http_status(:success)
    end

    context 'when update service returns errors' do
      let_it_be(:issue) { create(:work_item, :issue, project: project) }

      before do
        create(:parent_link, work_item: noteable, work_item_parent: issue)
      end

      it 'mutation response include the errors' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          noteable.reload
        end.not_to change { noteable.work_item_type.base_type }

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors'])
          .to include('Validation Work item type cannot be changed to issue when linked to a parent issue.')
      end
    end

    context 'when quick command for unsupported widget is present' do
      let(:body) { "\n/type Issue\n/assign @#{assignee.username}" }

      before do
        WorkItems::Type.default_by_type(:issue).widget_definitions
                       .find_by_widget_type(:assignees).update!(disabled: true)
      end

      it 'updates only type' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          noteable.reload
        end.to change { noteable.work_item_type.base_type }.from('task').to('issue')
                                                           .and change { noteable.assignees }.to([])

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to eq([])
        expect(mutation_response['quickActionsStatus']['messages'])
          .to include("Type changed successfully. Assigned @#{assignee.username}.")
        expect(mutation_response['quickActionsStatus']['error_messages']).to be_nil
      end
    end

    context 'when the type name is upper case' do
      let(:body) { "Updating type.\n/type Issue" }

      it 'changes type to issue' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          noteable.reload
        end.to change { noteable.work_item_type.base_type }.from('task').to('issue')
      end
    end
  end

  context 'with /type quick command' do
    let(:body) { "Updating type.\n/type issue" }

    it_behaves_like 'a quick command that changes type'
  end

  context 'with /promote_to quick command' do
    let(:body) { "Updating type.\n/promote_to issue" }

    it_behaves_like 'a quick command that changes type'
  end
end
