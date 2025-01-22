# frozen_string_literal: true

RSpec.shared_examples 'fails to transfer work item' do |error_message|
  it 'does not raise error' do
    expect { service.execute }.not_to raise_error
  end

  it 'returns error response' do
    response = service.execute

    expect(response.success?).to be false
    expect(response.error?).to be true
    expect(response.message).to include(error_message)
  end
end

RSpec.shared_examples 'cloneable and moveable work item' do
  it 'increases the target namespace work items count by 1' do
    expect do
      service.execute
    end.to change { target_namespace.work_items.count }.by(1)
  end

  it 'runs all widget callbacks' do
    create_service_params = {
      work_item: anything, target_work_item: anything, current_user: current_user, params: anything
    }

    cleanup_service_params = {
      work_item: anything, target_work_item: nil, current_user: current_user, params: anything
    }

    original_work_item.widgets.flat_map(&:sync_data_callback_class).each do |callback_class|
      allow_next_instance_of(callback_class, **create_service_params) do |callback_instance|
        expect(callback_instance).to receive(:before_create)
        expect(callback_instance).to receive(:after_save_commit)
      end

      # move service also calls cleanup callbacks
      next unless described_class == WorkItems::DataSync::MoveService

      allow_next_instance_of(callback_class, **cleanup_service_params) do |callback_instance|
        expect(callback_instance).to receive(:post_move_cleanup)
      end
    end

    service.execute
  end

  it 'returns a new work item with the same attributes' do
    new_work_item = service.execute[:work_item]

    expect(new_work_item).to be_persisted
    expect(new_work_item).to have_attributes(original_work_item_attrs)
  end

  it 'handles original work item state' do
    service.execute

    expect(original_work_item.reload.state_id).to eq(expected_original_work_item_state)
  end
end

RSpec.shared_examples 'cloneable and moveable widget data' do
  include DesignManagementTestHelpers

  def work_item_assignees(work_item)
    work_item.reload.assignees
  end

  def work_item_award_emoji(work_item)
    work_item.reload.award_emoji.pluck(:user_id, :name)
  end

  def work_item_emails(work_item)
    work_item.reload.email_participants.pluck(:email)
  end

  def work_item_milestone(work_item)
    work_item.reload.milestone&.title
  end

  def work_item_subscriptions(work_item)
    work_item.reload.subscriptions.pluck(:user_id)
  end

  def work_item_sent_notifications(work_item)
    work_item.reload.sent_notifications.pluck(:recipient_id)
  end

  def work_item_timelogs(work_item)
    work_item.reload.timelogs.pluck(:user_id, :time_spent)
  end

  def work_item_crm_contacts(work_item)
    work_item.reload.customer_relations_contacts
  end

  def work_item_designs(work_item)
    work_item.reload.designs.pluck(:filename)
  end

  def work_item_labels(work_item)
    work_item.reload.labels.pluck(:title)
  end

  def work_item_children(work_item)
    work_item.reload.work_item_children.pluck(:title)
  end

  def work_item_parent(work_item)
    work_item.reload.work_item_parent
  end

  let_it_be(:users) { create_list(:user, 3) }
  let_it_be(:thumbs_ups) { create_list(:award_emoji, 2, name: 'thumbsup', awardable: original_work_item) }
  let_it_be(:thumbs_downs) { create_list(:award_emoji, 2, name: 'thumbsdown', awardable: original_work_item) }
  let_it_be(:award_emojis) { original_work_item.reload.award_emoji.pluck(:user_id, :name) }

  let_it_be(:subscriptions) do
    create_list(:subscription, 2, subscribable: original_work_item)
    # create subscriptions for original work item and return subscribers as `expected_data` for later comparison.
    original_work_item.reload.subscriptions.pluck(:user_id)
  end

  let_it_be(:notifications) do
    create_list(:sent_notification, 2, noteable: original_work_item,
      project: original_work_item.project, recipient: create(:user)
    )
    # create sent notification for original work item and return recipients as `expected_data` for later comparison.
    original_work_item.reload.sent_notifications.pluck(:recipient_id)
  end

  let_it_be(:crm_contacts) do
    # create a crm group and assign it to both original and new work item namespaces in order to be able to move the
    # crm contacts from the original one to the new one
    crm_group = create(:group)
    create(:crm_settings, group: group, source_group: crm_group)

    # The target_namespace can be a `Group`, `Namespaces::ProjectNamespace` or `Project`, we fetch the group, based
    # on the namespace type. Also we check that the `target group`` is different that the group, as there will
    # be validation errors when we create the crm_settings
    if target_namespace.is_a?(Group)
      create(:crm_settings, group: target_namespace, source_group: crm_group) if target_namespace != group
    elsif target_namespace.is_a?(Namespaces::ProjectNamespace) || target_namespace.is_a?(Project)
      create(:crm_settings, group: target_namespace.group, source_group: crm_group) if target_namespace.group != group
    end

    contacts = create_list(:contact, 2, group: crm_group)
    original_work_item.customer_relations_contacts << contacts
    # set the crm_contacts on the before_all call and return the contacts as `expected_data` for later comparison as the
    # cleanup callback will delete the association
    contacts
  end

  let_it_be(:emails) do
    create_list(:issue_email_participant, 2, issue: original_work_item)
    # create email participants on original work item and return emails as `expected_data` for later comparison.
    original_work_item.reload.email_participants.map(&:email)
  end

  let_it_be(:assignees) do
    original_work_item.assignee_ids = users.map(&:id)
    # set assignees and return assigned users as `expected_data` for later comparison.
    users
  end

  let_it_be(:milestone) do
    milestone = if original_work_item.namespace.is_a?(Group)
                  create(:milestone, group: original_work_item.namespace)
                else
                  create(:project_milestone, project: original_work_item.project)
                end

    original_work_item.update!(milestone: milestone)

    # create milestone with same title in destination namespace so that it can be assigned to moved work item
    if target_namespace.is_a?(Group)
      create(:milestone, group: target_namespace, title: milestone.title)
    elsif target_namespace.is_a?(Namespaces::ProjectNamespace)
      create(:project_milestone, project: target_namespace.project, title: milestone.title)
    else
      create(:project_milestone, project: target_namespace, title: milestone.title)
    end

    milestone.title
  end

  let_it_be(:timelogs) do
    timelogs = create_list(:timelog, 2, issue: original_work_item)
    timelogs.pluck(:user_id, :time_spent)
  end

  let_it_be(:designs) do
    designs = create_list(:design, 2, :with_lfs_file, issue: original_work_item)
    # we need to create an owner for the group, as it is needed when we try to copy the desigins to the new namespace
    group.add_owner(create(:user))
    designs.pluck(:filename)
  end

  let_it_be(:labels) do
    labels = []
    if original_work_item.namespace.is_a?(Group)
      labels = create_list(:group_label, 2, group: original_work_item.namespace)
      create(:group_label, group: target_namespace, title: labels.first.name)
    else
      labels = create_list(:label, 2, project: original_work_item.project)
      create(:label, project: target_namespace.project, title: labels.first.name)
    end

    original_work_item.update!(labels: labels)
    [labels.first.title]
  end

  let_it_be(:child_items) do
    child_item_type1 =  WorkItems::HierarchyRestriction.where(parent_type: original_work_item.work_item_type).order(
      id: :asc).first.child_type.base_type
    child_item_type2 =  WorkItems::HierarchyRestriction.where(parent_type: original_work_item.work_item_type).order(
      id: :asc).last.child_type.base_type

    child_item1 = create(:work_item, child_item_type1)
    create(:parent_link, work_item: child_item1, work_item_parent: original_work_item)
    child_item2 = create(:work_item, child_item_type2)
    create(:parent_link, work_item: child_item2, work_item_parent: original_work_item)

    [child_item1, child_item2].pluck(:title)
  end

  let_it_be(:parent) do
    parent = create(:work_item, :epic)
    create(:parent_link, work_item: original_work_item, work_item_parent: parent)
    parent
  end

  let_it_be(:move) { WorkItems::DataSync::MoveService }
  let_it_be(:clone) { WorkItems::DataSync::CloneService }

  # rubocop: disable Layout/LineLength -- improved readability with one line per widget
  let_it_be(:widgets) do
    [
      { widget_name: :assignees,                   eval_value: :work_item_assignees,          expected_data: assignees,     operations: [move, clone] },
      { widget_name: :award_emoji,                 eval_value: :work_item_award_emoji,        expected_data: award_emojis,  operations: [move] },
      { widget_name: :email_participants,          eval_value: :work_item_emails,             expected_data: emails,        operations: [move] },
      { widget_name: :milestone,                   eval_value: :work_item_milestone,          expected_data: milestone,     operations: [move, clone] },
      { widget_name: :subscriptions,               eval_value: :work_item_subscriptions,      expected_data: subscriptions, operations: [move] },
      { widget_name: :sent_notifications,          eval_value: :work_item_sent_notifications, expected_data: notifications, operations: [move] },
      { widget_name: :timelogs,                    eval_value: :work_item_timelogs,           expected_data: timelogs,      operations: [move] },
      { widget_name: :customer_relations_contacts, eval_value: :work_item_crm_contacts,       expected_data: crm_contacts,  operations: [move, clone] },
      { widget_name: :designs,                     eval_value: :work_item_designs,            expected_data: designs,       operations: [move, clone] },
      { widget_name: :labels,                      eval_value: :work_item_labels,             expected_data: labels,        operations: [move, clone] },
      { widget_name: :work_item_children,          eval_value: :work_item_children,           expected_data: child_items,   operations: [move] },
      { widget_name: :work_item_parent,            eval_value: :work_item_parent,             expected_data: parent,        operations: [move, clone] }
    ]
  end
  # rubocop: enable Layout/LineLength

  context "with widget" do
    before do
      enable_design_management
      allow(original_work_item).to receive(:from_service_desk?).and_return(true)
    end

    it_behaves_like 'for clone and move services'
  end
end

# this shared example is only to be used for sharing the code between the shared examples for cloneable and movable
# widget data (and for EE widget data)
RSpec.shared_examples 'for clone and move services' do
  it 'clones and moves the data', :aggregate_failures, :sidekiq_inline do
    new_work_item = service.execute[:work_item]

    widgets.each do |widget|
      # This example is being called from EE spec where we text move/clone on a group level work item(Epic).
      # Designs are only available for project level work items so we will skip the spec group level work items.
      next if widget[:widget_name] == :designs && original_work_item.project.blank?

      widget_value = send(widget[:eval_value], new_work_item)

      if widget[:operations].include?(described_class)
        expect(widget_value).not_to be_blank
        # trick to compare single values and arrays with a single statement
        expect([widget_value].flatten).to match_array([widget[:expected_data]].flatten)
      else
        expect(widget_value).to be_blank
      end

      non_cleanupable_widgets = [:sent_notifications, :work_item_children]
      cleanup_data = Feature.enabled?(:cleanup_data_source_work_item_data, original_work_item.resource_parent)

      if cleanup_data && described_class == move
        expect(original_work_item.reload.public_send(widget[:widget_name])).to be_blank
      elsif non_cleanupable_widgets.exclude?(widget[:widget_name])
        # sent notifications and child work items are re-linked to new work item during the `move`
        # rather than deleted afterwards, so the original work item loses these items even before getting to the
        # cleanup data step.
        expect(original_work_item.reload.public_send(widget[:widget_name])).not_to be_blank
      end
    end
  end
end
