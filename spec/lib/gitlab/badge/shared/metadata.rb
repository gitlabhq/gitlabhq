shared_examples 'badge metadata' do
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
end
