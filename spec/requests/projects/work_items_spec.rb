# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items' do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:developer) { create(:user) }

  before_all do
    work_item.project.add_developer(developer)
  end

  describe 'GET /:namespace/:project/work_items/:id' do
    before do
      sign_in(developer)
    end

    it 'renders index' do
      get project_work_items_url(work_item.project, work_items_path: work_item.id)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
