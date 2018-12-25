require 'spec_helper'

describe API::Releases do
  let(:user) { create(:user) }
  let(:guest) { create(:user).tap { |u| project.add_guest(u) } }
  let(:project) { create(:project, :repository, creator: user, path: 'my.project') }
  let(:tag_name) { project.repository.find_tag('v1.1.0').name }

  let(:project_id) { project.id }
  let(:current_user) { nil }

  before do
    project.add_maintainer(user)
  end

  describe 'GET /projects/:id/releases' do
    # TODO:
  end

  describe 'GET /projects/:id/releases/:tag_name' do
    # TODO:
  end

  describe 'POST /projects/:id/releases' do
    # TODO:
  end

  describe 'PUT /projects/:id/releases/:tag_name' do
    # TODO:
  end

  describe 'DELETE /projects/:id/releases/:tag_name' do
    # TODO:
  end
end
