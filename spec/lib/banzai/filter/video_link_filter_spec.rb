require 'spec_helper'

describe Banzai::Filter::VideoLinkFilter, lib: true do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      project: project
    })

    described_class.call(doc, contexts)
  end

  def link_to_image(path)
    %(<img src="#{path}" />)
  end

  let(:project) { create(:project) }

  context 'when the element src has a video extension' do
    UploaderHelper::VIDEO_EXT.each do |ext|
      it "replaces the image tag 'path/video.#{ext}' with a video tag" do
        element = filter(link_to_image("/path/video.#{ext}")).children.first

        expect(element.name).to eq 'video'
        expect(element['src']).to eq "/path/video.#{ext}"

        fallback_link = element.children.first
        expect(fallback_link.name).to eq 'a'
        expect(fallback_link['href']).to eq "/path/video.#{ext}"
        expect(fallback_link['target']).to eq '_blank'
      end
    end
  end

  context 'when the element src is an image' do
    it 'leaves the document unchanged' do
      element = filter(link_to_image("/path/my_image.jpg")).children.first

      expect(element.name).to eq 'img'
    end
  end

end
