# frozen_string_literal: true

require 'spec_helper'

describe 'projects/show.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:admin) }
  let(:project) { create(:project, :repository) }

  before do
    presented_project = project.present(current_user: user)

    allow(presented_project).to receive(:default_view).and_return('customize_workflow')
    allow(controller).to receive(:current_user).and_return(user)

    assign(:project, presented_project)
  end

  context 'commit signatures' do
    context 'with vue tree view enabled' do
      it 'are not rendered via js-signature-container' do
        render

        expect(rendered).not_to have_css('.js-signature-container')
      end
    end

    context 'with vue tree view disabled' do
      before do
        stub_feature_flags(vue_file_list: false)
      end

      it 'rendered via js-signature-container' do
        render

        expect(rendered).to have_css('.js-signature-container')
      end
    end
  end
end
