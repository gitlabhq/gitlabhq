# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/environments/terminal' do
  let!(:environment) { create(:environment, :with_review_app) }

  before do
    assign(:environment, environment)
    assign(:project, environment.project)

    allow(view).to receive(:can?).and_return(true)
  end

  context 'when environment has external URL' do
    it 'shows external URL button' do
      environment.update_attribute(:external_url, 'https://gitlab.com')

      render

      expect(rendered).to have_link(nil, href: 'https://gitlab.com')
    end
  end

  context 'when environment does not have external URL' do
    it 'shows external URL button' do
      environment.update_attribute(:external_url, nil)

      render

      expect(rendered).not_to have_link(nil, href: 'https://gitlab.com')
    end
  end
end
