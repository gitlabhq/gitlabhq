# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_stat_anchor_list', feature_category: :source_code_management do
  def anchor(data)
    ProjectPresenter::AnchorData.new(false, 'Anchor label', '/anchor/path', nil, nil, nil, data)
  end

  it 'renders the internal events tracking attributes so the event fires on click' do
    render 'projects/stat_anchor_list',
      anchors: [anchor({ event_tracking: 'click_readme_on_project_overview', event_label: 'add' })],
      project_buttons: true

    expect(rendered).to trigger_internal_events('click_readme_on_project_overview')
      .on_click
      .with(additional_properties: { label: 'add' })
  end

  it 'renders tracking attributes for anchors without a label' do
    render 'projects/stat_anchor_list',
      anchors: [anchor({ event_tracking: 'click_integrations_on_project_overview' })],
      project_buttons: true

    expect(rendered).to trigger_internal_events('click_integrations_on_project_overview').on_click
  end
end
