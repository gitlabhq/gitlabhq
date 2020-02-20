# frozen_string_literal: true

require 'spec_helper'

describe 'projects/tree/_tree_header' do
  let(:project) { create(:project, :repository) }
  let(:current_user) { create(:user) }
  let(:repository) { project.repository }

  before do
    stub_feature_flags(vue_file_list: false)

    assign(:project, project)
    assign(:repository, repository)
    assign(:id, File.join('master', ''))
    assign(:ref, 'master')

    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:can_collaborate_with_project?) { true }
  end

  it 'renders the WebIDE button when user can collaborate but not create fork or MR' do
    allow(view).to receive(:can?) { false }

    render

    expect(rendered).to have_link('Web IDE')
  end

  it 'renders the WebIDE button when user can create fork and can open MR in project' do
    allow(view).to receive(:can?) { true }

    render

    expect(rendered).to have_link('Web IDE')
  end

  it 'opens a popup confirming a fork if the user can create fork/MR but cannot collaborate with the project' do
    allow(view).to receive(:can?) { true }
    allow(view).to receive(:can_collaborate_with_project?) { false }

    render

    expect(rendered).to have_link('Web IDE', href: '#modal-confirm-fork')
  end

  it 'does not render the WebIDE button when user cannot collaborate or create mr' do
    allow(view).to receive(:can?) { false }
    allow(view).to receive(:can_collaborate_with_project?) { false }

    render

    expect(rendered).not_to have_link('Web IDE')
  end
end
