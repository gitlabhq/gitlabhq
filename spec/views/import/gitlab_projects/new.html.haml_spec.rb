# frozen_string_literal: true

require 'spec_helper'

describe 'import/gitlab_projects/new.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:user) { build_stubbed(:user, namespace: build_stubbed(:namespace)) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when the user has no other namespaces' do
    it 'shows a namespace_id hidden field tag' do
      render

      expect(rendered).to have_css('input[name="namespace_id"]', count: 1, visible: false)
    end
  end

  context 'when the user can select other namespaces' do
    it 'shows a namespace_id select' do
      allow(user).to receive(:can_select_namespace?).and_return(true)

      render

      expect(rendered).to have_select('namespace_id', count: 1)
    end
  end
end
