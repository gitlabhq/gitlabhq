require 'spec_helper'

describe 'projects/blob/_viewer.html.haml', :view do
  include FakeBlobHelpers

  let(:project) { build(:empty_project) }

  let(:viewer_class) do
    Class.new(BlobViewer::Base) do
      include BlobViewer::Rich

      self.partial_name = 'text'
      self.max_size = 1.megabyte
      self.absolute_max_size = 5.megabytes
      self.client_side = false
    end
  end

  let(:viewer) { viewer_class.new(blob) }
  let(:blob) { fake_blob }

  before do
    assign(:project, project)
    assign(:id, File.join('master', blob.path))

    controller.params[:controller] = 'projects/blob'
    controller.params[:action] = 'show'
    controller.params[:namespace_id] = project.namespace.to_param
    controller.params[:project_id] = project.to_param
    controller.params[:id] = File.join('master', blob.path)
  end

  def render_view
    render partial: 'projects/blob/viewer', locals: { viewer: viewer }
  end

  context 'when the viewer is server side' do
    before do
      viewer_class.client_side = false
    end

    context 'when there is no render error' do
      it 'adds a URL to the blob viewer element' do
        render_view


        expect(rendered).to have_css('.blob-viewer[data-url]')
      end

      it 'displays a spinner' do
        render_view

        expect(rendered).to have_css('i[aria-label="Loading content"]')
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

  context 'when the viewer is client side' do
    before do
      viewer_class.client_side = true
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
