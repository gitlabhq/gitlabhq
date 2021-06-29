# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/milestones/_top.html.haml' do
  let_it_be(:group) { create(:group) }

  let(:project) { create(:project, group: group) }
  let(:milestone) { create(:milestone, project: project) }

  before do
    allow(milestone).to receive(:milestones) { [] }
    allow(milestone).to receive(:milestone) { milestone }
  end

  it 'does not render a deprecation message for a non-legacy and non-dashboard milestone' do
    assign :group, group

    render 'shared/milestones/top', milestone: milestone

    expect(rendered).not_to have_css('.milestone-deprecation-message')
  end
end
