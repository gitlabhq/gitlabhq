# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/ci_cd/_autodevops_form' do
  let(:project) { create(:project, :repository) }

  before do
    assign :project, project
    allow(view).to receive(:auto_devops_enabled) { true }
  end

  it 'renders the autodevops form' do
    render

    expect(rendered).to have_text('Default to Auto DevOps pipeline')
  end
end
