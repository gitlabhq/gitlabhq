# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'events/event/_created_project.html.haml', feature_category: :user_profile do
  let_it_be(:group) { build_stubbed(:group, name: 'Source Group') }
  let_it_be(:project) { build_stubbed(:project, name: 'Source Project', namespace: group) }
  let_it_be(:author) { build_stubbed(:user) }

  let_it_be(:event) do
    build_stubbed(
      :event,
      :created,
      project: project,
      target: project,
      target_type: 'Project',
      author: author
    )
  end

  before do
    render partial: 'events/event/created_project', locals: { event: event.present }
  end

  it 'renders a full-path project link', :aggregate_failures do
    expect(rendered).to have_link(project.name, href: project_path(project))
    expect(rendered).to include('namespace-name')
    expect(rendered).to include("#{project.namespace.human_name} /")
  end
end
