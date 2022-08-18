# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/blob/_viewer.html.haml' do
  include FakeBlobHelpers

  let(:project) { build(:project) }

  let(:viewer_class) do
    Class.new(BlobViewer::Base) do
      include BlobViewer::Rich

      self.partial_name = 'text'
      self.collapse_limit = 1.megabyte
      self.size_limit = 5.megabytes
      self.load_async = true
    end
  end

  let(:viewer) { viewer_class.new(blob) }
  let(:blob) { fake_blob }

  before do
    assign(:project, project)
    assign(:blob, blob)
    assign(:ref, 'master')
    assign(:id, File.join('master', blob.path))

    controller.params[:controller] = 'projects/blob'
    controller.params[:action] = 'show'
    controller.params[:namespace_id] = project.namespace.to_param
    controller.params[:project_id] = project.to_param
    controller.params[:id] = File.join('master', blob.path)

    allow(project.repository).to receive(:gitattribute).and_return(nil)
  end

  def render_view
    render partial: 'projects/blob/viewer', locals: { viewer: viewer }
  end

  context 'when the viewer is loaded asynchronously' do
    before do
      viewer_class.load_async = true
    end

    context 'when there is no render error' do
      it 'adds a URL to the blob viewer element' do
        render_view

        expect(rendered).to have_css('.blob-viewer[data-url]')
      end

      it 'renders the loading indicator' do
        render_view

        expect(view).to render_template('projects/blob/viewers/_loading')
      end
    end

    context 'when there is a render error' do
      let(:blob) { fake_blob(size: 10.megabytes) }

      it 'renders the error' do
        render_view

        expect(view).to render_template('projects/blob/_render_error')
      end
    end
  end

  context 'when the viewer is loaded synchronously' do
    before do
      viewer_class.load_async = false
    end

    context 'when there is no render error' do
      it 'prepares the viewer' do
        expect(viewer).to receive(:prepare!)

        render_view
      end

      it 'renders the viewer' do
        render_view

        expect(view).to render_template('projects/blob/viewers/_text')
      end
    end

    context 'when there is a render error' do
      let(:blob) { fake_blob(size: 10.megabytes) }

      it 'renders the error' do
        render_view

        expect(view).to render_template('projects/blob/_render_error')
      end
    end
  end
end
