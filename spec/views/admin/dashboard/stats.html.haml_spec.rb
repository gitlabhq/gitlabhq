# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dashboard/stats', feature_category: :seat_cost_management do
  let_it_be(:users_statistics) do
    build(:users_statistics, without_groups_and_projects: 10,
      with_highest_role_planner: 5,
      with_highest_role_reporter: 15,
      with_highest_role_developer: 25,
      with_highest_role_maintainer: 20,
      with_highest_role_owner: 3,
      with_highest_role_guest: 30,
      bots: 7,
      blocked: 5)
  end

  before do
    assign(:users_statistics, users_statistics)

    render
  end

  it 'displays users without groups and projects' do
    expect(rendered).to have_content('Users without a Group and Project')
    expect(rendered).to have_content('10')
  end

  it 'displays users with highest role for each role type' do
    expect(rendered).to have_content('Users with highest role Planner')
    expect(rendered).to have_content('5')

    expect(rendered).to have_content('Users with highest role Reporter')
    expect(rendered).to have_content('15')

    expect(rendered).to have_content('Users with highest role Developer')
    expect(rendered).to have_content('25')

    expect(rendered).to have_content('Users with highest role Maintainer')
    expect(rendered).to have_content('20')

    expect(rendered).to have_content('Users with highest role Owner')
    expect(rendered).to have_content('3')

    expect(rendered).to have_content('Users with highest role Guest')
    expect(rendered).to have_content('30')
  end

  it 'displays the number of bots' do
    expect(rendered).to have_content('Bots')
    expect(rendered).to have_content('7')
  end

  it 'renders a table with the correct structure' do
    expect(rendered).to have_content('Total users (active users + blocked users) 120')
  end
end
