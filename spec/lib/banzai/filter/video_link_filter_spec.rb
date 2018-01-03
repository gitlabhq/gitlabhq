require 'spec_helper'

describe Banzai::Filter::VideoLinkFilter do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      project: project
    })

    described_class.call(doc, contexts)
  end

  def link_to_image(path)
    %(<img src="#{path}" />)
  end

  let(:project) { create(:project, :repository) }

  context 'when the element src has a video extension' do
    UploaderHelper::VIDEO_EXT.each do |ext|
      it "replaces the image tag 'path/video.#{ext}' with a video tag" do
        container = filter(link_to_image("/path/video.#{ext}")).children.first

        expect(container.name).to eq 'div'
        expect(container['class']).to eq 'video-container'

        video, paragraph = container.children

        expect(video.name).to eq 'video'
        expect(video['src']).to eq "/path/video.#{ext}"

        expect(paragraph.name).to eq 'p'

        link = paragraph.children.first

        expect(link.name).to eq 'a'
        expect(link['href']).to eq "/path/video.#{ext}"
        expect(link['target']).to eq '_blank'
      end
    end
  end

  context 'when the element src is an image' do
    it 'leaves the document unchanged' do
      element = filter(link_to_image('/path/my_image.jpg')).children.first

      expect(element.name).to eq 'img'
      expect(element['src']).to eq '/path/my_image.jpg'
    end
  end
end
