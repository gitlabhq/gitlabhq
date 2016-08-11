require 'spec_helper'

describe Gitlab::Badge::Build::Metadata do
  let(:badge) { double(project: create(:project), ref: 'feature') }
  let(:metadata) { described_class.new(badge) }

  describe '#to_html' do
    let(:html) { Nokogiri::HTML.parse(metadata.to_html) }
    let(:a_href) { html.at('a') }

    it 'points to link' do
      expect(a_href[:href]).to eq metadata.link_url
    end

    it 'contains clickable image' do
      expect(a_href.children.first.name).to eq 'img'
    end
  end

  describe '#to_markdown' do
    subject { metadata.to_markdown }

    it { is_expected.to include metadata.image_url }
    it { is_expected.to include metadata.link_url }
  end

  describe '#image_url' do
    it 'returns valid url' do
      expect(metadata.image_url).to include 'badges/feature/build.svg'
    end
  end

  describe '#link_url' do
    it 'returns valid link' do
      expect(metadata.link_url).to include 'commits/feature'
    end
  end
end
