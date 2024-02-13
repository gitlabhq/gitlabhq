# frozen_string_literal: true

RSpec.shared_context 'with container for work items service' do |container_type|
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_reload(:group) { create(:group) }

  let_it_be(:container) do
    case container_type
    when :project then project
    when :project_namespace then project.project_namespace
    when :group then group
    end
  end

  let_it_be(:container_args) do
    case container_type
    when :project, :project_namespace then { project: project }
    when :group then { namespace: group }
    end
  end

  let_it_be(:parent) { create(:work_item, **container_args) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:user_with_no_access) { create(:user) }

  let(:widget_params) { {} }
  let(:extra_params) { {} }
  let(:perform_spam_check) { false }
  let(:current_user) { guest }
  let(:opts) do
    {
      title: 'Awesome work_item',
      description: 'please fix'
    }
  end

  let(:service) do
    described_class.new(
      container: container,
      current_user: current_user,
      params: opts.merge(extra_params),
      perform_spam_check: perform_spam_check,
      widget_params: widget_params
    )
  end

  before_all do
    memberships_container = container.is_a?(Namespaces::ProjectNamespace) ? container.reload.project : container
    memberships_container.add_guest(guest)
    memberships_container.add_reporter(reporter)
  end
end
