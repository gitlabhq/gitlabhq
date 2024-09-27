# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ImageLinkFilter, feature_category: :markdown do
  include FilterSpecHelper

  let(:path) { '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg' }
  let(:context) { {} }

  def image(path, alt: nil, data_src: nil)
    alt_tag = alt ? %(alt="#{alt}") : ""
    data_src_tag = data_src ? %(data-src="#{data_src}") : ""

    %(<img src="#{path}" #{alt_tag} #{data_src_tag} />)
  end

  it 'wraps the image with a link to the image src' do
    doc = filter(image(path), context)

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
  end

  it 'ignores images with empty data-src' do
    doc = filter(image(path, data_src: ''), context)

    expect(doc.at_css('a')).to be_nil
  end

  it 'does not wrap a duplicate link' do
    doc = filter(%(<a href="/whatever">#{image(path)}</a>), context)

    expect(doc.to_html).to match %r{^<a href="/whatever"><img[^>]*></a>$}
  end

  it 'works with external images' do
    doc = filter(image('https://i.imgur.com/DfssX9C.jpg'), context)

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
  end

  it 'works with inline images' do
    doc = filter(%(<p>test #{image(path)} inline</p>), context)

    expect(doc.to_html).to match %r{^<p>test <a[^>]*><img[^>]*></a> inline</p>$}
  end

  it 'keep the data-canonical-src' do
    doc = filter(
      %q(<img src="http://assets.example.com/6cd/4d7" data-canonical-src="http://example.com/test.png" />),
      context
    )

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
    expect(doc.at_css('img')['data-canonical-src']).to eq doc.at_css('a')['data-canonical-src']
  end

  it 'moves the data-diagram* attributes' do
    # rubocop:disable Layout/LineLength
    doc = filter(
      %q(<img class="plantuml" src="http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd91m0rkGMq" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IFNhcmEgOiBIZWxsbw==">),
      context
    )
    # rubocop:enable Layout/LineLength

    expect(doc.at_css('a')['data-diagram']).to eq "plantuml"
    expect(doc.at_css('a')['data-diagram-src']).to eq "data:text/plain;base64,Qm9iIC0+IFNhcmEgOiBIZWxsbw=="

    expect(doc.at_css('a img')['data-diagram']).to be_nil
    expect(doc.at_css('a img')['data-diagram-src']).to be_nil
  end

  it 'adds no-attachment icon class to the link' do
    doc = filter(image(path), context)

    expect(doc.at_css('a')['class']).to match(%r{no-attachment-icon})
  end

  context 'when :link_replaces_image is true' do
    let(:context) { { link_replaces_image: true } }

    it 'replaces the image with link to image src', :aggregate_failures do
      doc = filter(image(path), context)

      expect(doc.to_html).to match(%r{^<a[^>]*>#{path}</a>$})
      expect(doc.at_css('a')['href']).to eq(path)
    end

    it 'uses image alt as a link text', :aggregate_failures do
      doc = filter(image(path, alt: 'My image'), context)

      expect(doc.to_html).to match(%r{^<a[^>]*>My image</a>$})
      expect(doc.at_css('a')['href']).to eq(path)
    end

    it 'uses image data-src as a link text', :aggregate_failures do
      data_src = '/uploads/data-src.png'
      doc = filter(image(path, data_src: data_src), context)

      expect(doc.to_html).to match(%r{^<a[^>]*>#{data_src}</a>$})
      expect(doc.at_css('a')['href']).to eq(data_src)
    end

    it 'adds attachment icon class to the link' do
      doc = filter(image(path), context)

      expect(doc.at_css('a')['class']).to match(%r{with-attachment-icon})
    end

    context 'when link attributes contain malicious code' do
      let(:malicious_code) do
        # rubocop:disable Layout/LineLength
        %q(<a class='fixed-top fixed-bottom' data-create-path=/malicious-url><style> .tab-content>.tab-pane{display: block !important}</style>)
        # rubocop:enable Layout/LineLength
      end

      context 'when image alt contains malicious code' do
        it 'ignores image alt and uses image path as the link text', :aggregate_failures do
          doc = filter(image(path, alt: malicious_code), context)

          expect(doc.to_html).to match(%r{^<a[^>]*>#{path}</a>$})
          expect(doc.at_css('a')['href']).to eq(path)
        end
      end

      context 'when image src contains malicious code' do
        it 'ignores image src and does not use it as the link text' do
          doc = filter(image(malicious_code), context)

          expect(doc.to_html).to match(%r{^<a[^>]*></a>$})
        end

        it 'keeps image src unchanged, malicious code does not execute as part of url' do
          doc = filter(image(malicious_code), context)

          expect(doc.at_css('a')['href']).to eq(malicious_code)
        end
      end

      context 'when image data-src contains malicious code' do
        it 'ignores data-src and uses image path as the link text', :aggregate_failures do
          doc = filter(image(path, data_src: malicious_code), context)

          expect(doc.to_html).to match(%r{^<a[^>]*>#{path}</a>$})
        end

        it 'uses image data-src, malicious code does not execute as part of url' do
          doc = filter(image(path, data_src: malicious_code), context)

          expect(doc.at_css('a')['href']).to eq(malicious_code)
        end
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
