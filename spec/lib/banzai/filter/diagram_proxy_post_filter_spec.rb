# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::DiagramProxyPostFilter, feature_category: :markdown do
  include FilterSpecHelper

  let(:current_user) { create(:user) }

  def build_img(diagram_type:, source:, lazy: false)
    encoded = Base64.strict_encode64(source)
    Nokogiri::HTML.fragment('').tap do |doc|
      doc.add_child(Nokogiri::XML::Node.new('img', doc).tap do |img|
        img['data-diagram'] = diagram_type
        img['data-diagram-src'] = "data:text/plain;base64,#{encoded}"
        if lazy
          img['class'] = 'lazy'
          img['data-src'] = img['src']
          img['src'] = LazyImageTagHelper.placeholder_image
        end
      end)
    end.to_html
  end

  def build_image_link(diagram_type:, source:, lazy: false)
    img_html = build_img(diagram_type: diagram_type, source: source, lazy: lazy)
    Banzai::Filter::ImageLinkFilter.call(img_html, {}).to_html
  end

  def build_invalid_img(diagram_type:, data_diagram_src:)
    Nokogiri::HTML.fragment('').tap do |doc|
      doc.add_child(Nokogiri::XML::Node.new('img', doc).tap do |img|
        img['data-diagram'] = diagram_type
        img['data-diagram-src'] = data_diagram_src
      end)
    end.to_html
  end

  describe 'plantuml diagrams' do
    before do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")
    end

    context 'when plantuml_diagram_proxy_enabled is true' do
      before do
        stub_application_setting(plantuml_diagram_proxy_enabled: true)
      end

      it 'replaces src with proxy URL and stores diagram data in Redis' do
        input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
        doc = filter(input, current_user: current_user)

        img = doc.at_css('img')
        expect(img['src']).to match(%r{/-/diagram-proxy/})

        key = img['src'].match(%r{/-/diagram-proxy/(.+)})[1]
        stored = described_class.getdel(key)
        data = Gitlab::Json.safe_parse(stored)

        expect(data['user_id']).to eq(current_user.id)
        expect(data['diagram_type']).to eq('plantuml')
        expect(data['diagram_source']).to eq('Bob -> Sara : Hello')
      end

      it 'works without a current_user' do
        input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
        doc = filter(input)

        img = doc.at_css('img')
        expect(img['src']).to match(%r{/-/diagram-proxy/})

        key = img['src'].match(%r{/-/diagram-proxy/(.+)})[1]
        stored = described_class.getdel(key)
        data = Gitlab::Json.safe_parse(stored)

        expect(data['user_id']).to be_nil
      end
    end

    context 'when plantuml_diagram_proxy_enabled is false' do
      before do
        stub_application_setting(plantuml_diagram_proxy_enabled: false)
      end

      it 'does not modify plantuml diagram nodes' do
        input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
        doc = filter(input)

        expect(doc.at_css('img')['src']).to be_nil
      end
    end

    context 'when kroki proxy is enabled but plantuml proxy is disabled' do
      before do
        stub_application_setting(
          kroki_enabled: true, kroki_url: "http://localhost:8000",
          kroki_diagram_proxy_enabled: true,
          plantuml_diagram_proxy_enabled: false
        )
      end

      it 'skips plantuml diagram nodes' do
        input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
        doc = filter(input)

        expect(doc.at_css('img')['src']).to be_nil
      end
    end
  end

  describe 'kroki diagrams' do
    before do
      stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    end

    context 'when kroki_diagram_proxy_enabled is true' do
      before do
        stub_application_setting(kroki_diagram_proxy_enabled: true)
      end

      it 'replaces src with proxy URL for supported kroki diagram types' do
        input = build_img(diagram_type: 'graphviz', source: 'digraph { a -> b }')
        doc = filter(input, current_user: current_user)

        img = doc.at_css('img')
        expect(img['src']).to match(%r{/-/diagram-proxy/})

        key = img['src'].match(%r{/-/diagram-proxy/(.+)})[1]
        stored = described_class.getdel(key)
        data = Gitlab::Json.safe_parse(stored)

        expect(data['diagram_type']).to eq('graphviz')
        expect(data['diagram_source']).to eq('digraph { a -> b }')
      end

      it 'does not modify unsupported diagram types' do
        input = build_img(diagram_type: 'unsupported_type', source: 'some content')
        doc = filter(input)

        expect(doc.at_css('img')['src']).to be_nil
      end
    end

    context 'when kroki_diagram_proxy_enabled is false' do
      before do
        stub_application_setting(kroki_diagram_proxy_enabled: false)
      end

      it 'does not modify kroki diagram nodes' do
        input = build_img(diagram_type: 'graphviz', source: 'digraph { a -> b }')
        doc = filter(input)

        expect(doc.at_css('img')['src']).to be_nil
      end
    end
  end

  describe 'when both proxies are disabled' do
    before do
      stub_application_setting(plantuml_diagram_proxy_enabled: false)
      stub_application_setting(kroki_diagram_proxy_enabled: false)
    end

    it 'returns doc unchanged' do
      input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
      doc = filter(input)

      expect(doc.to_html).to eq(input)
    end
  end

  describe 'handling invalid base64 in data-diagram-src' do
    before do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")
      stub_application_setting(plantuml_diagram_proxy_enabled: true)
    end

    it 'removes the node when data-diagram-src contains invalid base64' do
      input = build_invalid_img(diagram_type: 'plantuml',
        data_diagram_src: 'data:text/plain;base64,not-valid-base64!!!')

      expect(filter(input).to_html).to eq ''
    end

    it 'continues processing other valid nodes' do
      valid_input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
      invalid_input = build_invalid_img(diagram_type: 'plantuml',
        data_diagram_src: 'data:text/plain;base64,!!invalid!!')
      combined = "#{invalid_input}#{valid_input}"

      doc = filter(combined)

      expect(doc.css('img').count).to eq(1)
      expect(doc.at_css('img')['src']).to match(%r{/-/diagram-proxy/})
    end
  end

  describe 'interaction with ImageLinkFilter' do
    before do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")
      stub_application_setting(plantuml_diagram_proxy_enabled: true)
    end

    it 'unwraps the <a> and sets proxy URL on the <img>' do
      input = build_image_link(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
      doc = filter(input, current_user: current_user)

      expect(doc.at_css('a')).to be_nil

      img = doc.at_css('img')
      expect(img['src']).to match(%r{/-/diagram-proxy/})
      expect(img['data-diagram']).to eq('plantuml')
      expect(img['data-diagram-src']).to be_present
    end

    it 'stores the correct diagram data in Redis' do
      input = build_image_link(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
      doc = filter(input, current_user: current_user)

      key = doc.at_css('img')['src'].match(%r{/-/diagram-proxy/(.+)})[1]
      data = Gitlab::Json.safe_parse(described_class.getdel(key))

      expect(data['user_id']).to eq(current_user.id)
      expect(data['diagram_type']).to eq('plantuml')
      expect(data['diagram_source']).to eq('Bob -> Sara : Hello')
    end

    it 'applies lazy load when the inner img has lazy class' do
      input = build_image_link(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello', lazy: true)
      doc = filter(input, current_user: current_user)

      expect(doc.at_css('a')).to be_nil

      img = doc.at_css('img')
      expect(img['src']).to eq LazyImageTagHelper.placeholder_image
      expect(img['data-src']).to match(%r{/-/diagram-proxy/})
      expect(img.classes).to include('lazy')
    end
  end

  describe 'interaction with ImageLazyLoadFilter' do
    before do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")
      stub_application_setting(plantuml_diagram_proxy_enabled: true)
    end

    context 'when ImageLazyLoadFilter has run (node has lazy class)' do
      it 'applies lazy load to the proxy URL' do
        input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello', lazy: true)
        doc = filter(input, current_user: current_user)

        img = doc.at_css('img')
        expect(img['src']).to eq LazyImageTagHelper.placeholder_image
        expect(img['data-src']).to match(%r{/-/diagram-proxy/})
        expect(img.classes).to include('lazy')
        expect(img['decoding']).to eq 'async'
      end
    end

    context 'when ImageLazyLoadFilter has not run (node lacks lazy class)' do
      it 'does not apply lazy load' do
        input = build_img(diagram_type: 'plantuml', source: 'Bob -> Sara : Hello')
        doc = filter(input, current_user: current_user)

        img = doc.at_css('img')
        expect(img['src']).to match(%r{/-/diagram-proxy/})
        expect(img['data-src']).to be_nil
        expect(img.classes).not_to include('lazy')
      end
    end
  end

  describe '.store and .getdel' do
    it 'stores and retrieves data from Redis' do
      data = { user_id: 1, diagram_type: 'plantuml', diagram_source: 'test' }
      key = described_class.store(data)

      retrieved = described_class.getdel(key)
      expect(Gitlab::Json.safe_parse(retrieved)).to eq(data.stringify_keys)
    end

    it 'deletes the key after fetching' do
      data = { user_id: 1, diagram_type: 'plantuml', diagram_source: 'test' }
      key = described_class.store(data)

      described_class.getdel(key)
      expect(described_class.getdel(key)).to be_nil
    end

    it 'returns nil for non-existent keys' do
      expect(described_class.getdel('non-existent-key')).to be_nil
    end
  end

  it_behaves_like 'pipeline timing check'
end
