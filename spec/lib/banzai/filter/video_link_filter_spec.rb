require 'spec_helper'

describe Banzai::Filter::VideoLinkFilter, lib: true do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      project: project
    })

    described_class.call(doc, contexts)
  end

  def image(path)
    %(<img src="#{path}" />)
  end

  let(:project) { create(:project) }

  context 'when the element src has a video extension' do
    it 'replaces the image tag with a video tag' do
      doc = filter(image("/path/video.mov"))
      element = doc.children.first
      expect(element.name).to eq( "video" )
      expect(element['src']).to eq( "/path/video.mov" )
    end
  end

  context 'when the element src is an image' do
    it 'leaves the document unchanged' do
      doc = filter(image("/path/my_image.jpg"))
      element = doc.children.first
      expect(element.name).to eq( "img" )
    end
  end


end
