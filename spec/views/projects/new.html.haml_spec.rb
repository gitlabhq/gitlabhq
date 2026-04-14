# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/new', feature_category: :groups_and_projects do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build(:project) }
  let_it_be(:namespace) { user.namespace }

  before do
    assign(:project, project)
    assign(:namespace, namespace)

    allow(view).to receive_messages(
      current_user: user,
      import_sources_enabled?: false,
      remote_mirror_setting_enabled?: false,
      brand_new_project_guidelines: nil,
      push_to_create_project_command: '',
      namespace_id_from: nil,
      can_push_initial_commit_to_namespace?: true
    )
  end

  describe 'page title' do
    before do
      allow(view).to receive(:page_title)
    end

    it 'sets the correct page title' do
      render

      expect(view).to have_received(:page_title).with(_('New project'))
    end
  end
end
