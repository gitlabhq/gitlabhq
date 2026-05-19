# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/registrations/groups/new', feature_category: :onboarding do
  let(:group) { build_stubbed(:group) }
  let(:project) { build_stubbed(:project) }

  let(:project_templates) { Gitlab::ProjectTemplate.all }

  before do
    assign(:group, group)
    assign(:project, project)
    assign(:project_templates, project_templates)
    assign(:template_name, '')
    allow(view).to receive_messages(
      admin_registrations_groups_path: '/admin/sign_up/groups',
      new_admin_registrations_profile_path: '/admin/registrations/profile/new'
    )
  end

  it 'renders the page heading' do
    render

    expect(rendered).to have_css('h2', text: 'Create your first project')
  end

  it 'renders a form posting to the groups path' do
    render

    expect(rendered).to have_css("form[action='/admin/sign_up/groups'][method='post']")
  end

  it 'renders the group name input' do
    render

    expect(rendered).to have_field('group[name]')
  end

  it 'renders the project name input' do
    render

    expect(rendered).to have_field('project[name]')
  end

  it 'does not render hidden fields for visibility_level' do
    render

    expect(rendered).not_to have_css("input[type='hidden'][name='group[visibility_level]']", visible: :hidden)
    expect(rendered).not_to have_css("input[type='hidden'][name='project[visibility_level]']", visible: :hidden)
  end

  it 'does not render a hidden field for organization_id' do
    render

    expect(rendered).not_to have_css("input[type='hidden'][name='group[organization_id]']", visible: :hidden)
  end

  it 'renders the project template select with "Blank project (default)" as the default option' do
    render

    expect(rendered).to have_select('project[project_template_name]', selected: 'Blank project (default)')
  end

  it 'renders the template field as optional' do
    render

    expect(rendered).to have_content('(optional)')
  end

  it 'renders a template option for each project template' do
    render

    project_templates.each do |template|
      expect(rendered).to have_css("option[value='#{template.name}']", text: template.title)
    end
  end

  it 'renders a submit button labeled Continue' do
    render

    expect(rendered).to have_button('Continue')
  end

  it 'renders a skip link to the profile step' do
    render

    expect(rendered).to have_link('Skip', href: '/admin/registrations/profile/new')
  end
end
