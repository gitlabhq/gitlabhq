# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/diffs/_viewer.html.haml' do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
  let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

  let(:viewer) { diff_file.simple_viewer }

  before do
    assign(:project, project)

    controller.params[:controller] = 'projects/commit'
    controller.params[:action] = 'show'
    controller.params[:namespace_id] = project.namespace.to_param
    controller.params[:project_id] = project.to_param
    controller.params[:id] = commit.id
  end

  def render_view
    render partial: 'projects/diffs/viewer', locals: { viewer: viewer }
  end

  context 'when there is a render error' do
    before do
      allow(viewer).to receive(:render_error).and_return(:too_large)
    end

    it 'renders the error' do
      render_view

      expect(view).to render_template('projects/diffs/_render_error')
    end
  end

  context 'when the viewer is collapsed' do
    before do
      allow(diff_file).to receive(:collapsed?).and_return(true)
    end

    it 'renders the collapsed view' do
      render_view

      expect(view).to render_template('projects/diffs/viewers/_collapsed')
    end
  end

  context 'when there is no render error' do
    it 'prepares the viewer' do
      expect(viewer).to receive(:prepare!)

      render_view
    end

    it 'renders the viewer' do
      render_view

      expect(view).to render_template('projects/diffs/viewers/_text')
    end
  end
end
