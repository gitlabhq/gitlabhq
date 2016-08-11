require 'spec_helper'

describe Gitlab::Badge::Build::Metadata do
  let(:project) { create(:project) }
  let(:branch) { 'master' }
  let(:badge) { described_class.new(project, branch) }

  describe '#to_html' do
    let(:html) { Nokogiri::HTML.parse(badge.to_html) }
    let(:a_href) { html.at('a') }

    it 'points to link' do
      expect(a_href[:href]).to eq badge.link_url
    end

    it 'contains clickable image' do
      expect(a_href.children.first.name).to eq 'img'
    end
  end

  describe '#to_markdown' do
    subject { badge.to_markdown }

    it { is_expected.to include badge.image_url }
    it { is_expected.to include badge.link_url }
  end

  describe '#image_url' do
    subject { badge.image_url }
    it { is_expected.to include "badges/#{branch}/build.svg" }
  end

  describe '#link_url' do
    subject { badge.link_url }
    it { is_expected.to include "commits/#{branch}" }
  end
end
