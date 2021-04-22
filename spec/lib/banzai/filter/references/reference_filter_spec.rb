# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::ReferenceFilter do
  let(:project) { build_stubbed(:project) }

  describe '#each_node' do
    it 'iterates over the nodes in a document' do
      document = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      filter = described_class.new(document, project: project)

      expect { |b| filter.each_node(&b) }
        .to yield_with_args(an_instance_of(Nokogiri::XML::Element))
    end

    it 'returns an Enumerator when no block is given' do
      document = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      filter = described_class.new(document, project: project)

      expect(filter.each_node).to be_an_instance_of(Enumerator)
    end

    it 'skips links with a "gfm" class' do
      document = Nokogiri::HTML.fragment('<a href="foo" class="gfm">foo</a>')
      filter = described_class.new(document, project: project)

      expect { |b| filter.each_node(&b) }.not_to yield_control
    end

    it 'skips text nodes in pre elements' do
      document = Nokogiri::HTML.fragment('<pre>foo</pre>')
      filter = described_class.new(document, project: project)

      expect { |b| filter.each_node(&b) }.not_to yield_control
    end
  end

  describe '#nodes' do
    it 'returns an Array of the HTML nodes' do
      document = Nokogiri::HTML.fragment('<a href="foo">foo</a>')
      filter = described_class.new(document, project: project)

      expect(filter.nodes).to eq([document.children[0]])
    end
  end

  RSpec.shared_context 'document nodes' do
    let(:document) { Nokogiri::HTML.fragment('<p data-sourcepos="1:1-1:18"></p>') }
    let(:nodes) { [] }
    let(:filter) { described_class.new(document, project: project) }
    let(:ref_pattern) { nil }
    let(:href_link) { nil }

    before do
      nodes.each do |node|
        document.children.first.add_child(node)
      end
    end
  end

  RSpec.shared_context 'new nodes' do
    let(:nodes) { [{ value: "1" }, { value: "2" }, { value: "3" }] }
    let(:expected_nodes) { [{ value: "1.1" }, { value: "1.2" }, { value: "1.3" }, { value: "2.1" }, { value: "2.2" }, { value: "2.3" }, { value: "3.1" }, { value: "3.2" }, { value: "3.3" }] }
    let(:new_nodes) do
      {
        0 => [{ value: "1.1" }, { value: "1.2" }, { value: "1.3" }],
        2 => [{ value: "3.1" }, { value: "3.2" }, { value: "3.3" }],
        1 => [{ value: "2.1" }, { value: "2.2" }, { value: "2.3" }]
      }
    end
  end

  RSpec.shared_examples 'replaces text' do |method_name, index|
    let(:args) { [filter.nodes[index], index, ref_pattern || href_link].compact }

    context 'when content didnt change' do
      it 'does not replace link node with html' do
        filter.send(method_name, *args) do
          existing_content
        end

        expect(filter).not_to receive(:replace_text_with_html)
      end
    end

    context 'when link node has changed' do
      let(:html) { %(text <a href="reference_url" class="gfm gfm-user" title="reference">Reference</a>) }

      it 'replaces reference node' do
        filter.send(method_name, *args) do
          html
        end

        expect(document.css('a').length).to eq 1
      end

      it 'calls replace_and_update_new_nodes' do
        expect(filter).to receive(:replace_and_update_new_nodes).with(filter.nodes[index], index, html)

        filter.send(method_name, *args) do
          html
        end
      end

      it 'stores filtered new nodes' do
        filter.send(method_name, *args) do
          html
        end

        expect(filter.instance_variable_get(:@new_nodes)).to eq({ index => [filter.each_node.to_a[index]] })
      end
    end
  end

  RSpec.shared_examples 'replaces document node' do |method_name|
    context 'when parent has only one node' do
      let(:nodes) { [node] }

      it_behaves_like 'replaces text', method_name, 0
    end

    context 'when parent has multiple nodes' do
      let(:node1) { Nokogiri::HTML.fragment('<span>span text</span>') }
      let(:node2) { Nokogiri::HTML.fragment('<span>text</span>') }

      context 'when pattern matches in the first node' do
        let(:nodes) { [node, node1, node2] }

        it_behaves_like 'replaces text', method_name, 0
      end

      context 'when pattern matches in the middle node' do
        let(:nodes) { [node1, node, node2] }

        it_behaves_like 'replaces text', method_name, 1
      end

      context 'when pattern matches in the last node' do
        let(:nodes) { [node1, node2, node] }

        it_behaves_like 'replaces text', method_name, 2
      end
    end
  end

  describe '#replace_text_when_pattern_matches' do
    include_context 'document nodes'
    let(:node) { Nokogiri::HTML.fragment('text @reference') }

    let(:ref_pattern) { %r{(?<!\w)@(?<user>[a-zA-Z0-9_\-\.]*)}x }

    context 'when node has no reference pattern' do
      let(:node) { Nokogiri::HTML.fragment('random text') }
      let(:nodes) { [node] }

      it 'skips node' do
        expect { |b| filter.send(:replace_text_when_pattern_matches, filter.nodes[0], 0, ref_pattern, &b) }.not_to yield_control
      end
    end

    it_behaves_like 'replaces document node', :replace_text_when_pattern_matches do
      let(:existing_content) { node.to_html }
    end
  end

  describe '#replace_link_node_with_text' do
    include_context 'document nodes'
    let(:node) { Nokogiri::HTML.fragment('<a>end text</a>') }

    it_behaves_like 'replaces document node', :replace_link_node_with_text do
      let(:existing_content) { node.text }
    end
  end

  describe '#replace_link_node_with_href' do
    include_context 'document nodes'
    let(:node) { Nokogiri::HTML.fragment('<a href="link">end text</a>') }
    let(:href_link) { CGI.unescape(node.attr('href').to_s) }

    it_behaves_like 'replaces document node', :replace_link_node_with_href do
      let(:existing_content) { href_link }
    end
  end

  describe '#call_and_update_nodes' do
    include_context 'new nodes'
    let(:document) { Nokogiri::HTML.fragment('<a href="foo">foo</a>') }
    let(:filter) { described_class.new(document, project: project) }

    it 'updates all new nodes', :aggregate_failures do
      filter.instance_variable_set('@nodes', nodes)

      expect(filter).to receive(:call) { filter.instance_variable_set('@new_nodes', new_nodes) }
      expect(filter).to receive(:with_update_nodes).and_call_original
      expect(filter).to receive(:update_nodes!).and_call_original

      filter.call_and_update_nodes

      expect(filter.result[:reference_filter_nodes]).to eq(expected_nodes)
    end
  end

  describe '.call' do
    include_context 'new nodes'

    let(:document) { Nokogiri::HTML.fragment('<a href="foo">foo</a>') }

    let(:result) { { reference_filter_nodes: nodes } }

    it 'updates all nodes', :aggregate_failures do
      expect_next_instance_of(described_class) do |filter|
        expect(filter).to receive(:call_and_update_nodes).and_call_original
        expect(filter).to receive(:with_update_nodes).and_call_original
        expect(filter).to receive(:call) { filter.instance_variable_set('@new_nodes', new_nodes) }
        expect(filter).to receive(:update_nodes!).and_call_original
      end

      described_class.call(document, { project: project }, result)

      expect(result[:reference_filter_nodes]).to eq(expected_nodes)
    end
  end

  context 'abstract methods' do
    let(:document) { Nokogiri::HTML.fragment('<a href="foo">foo</a>') }
    let(:filter) { described_class.new(document, project: project) }

    describe '#references_in' do
      it 'raises NotImplementedError' do
        expect { filter.references_in('foo', %r{(?<!\w)}) }.to raise_error(NotImplementedError)
      end
    end

    describe '#object_link_filter' do
      it 'raises NotImplementedError' do
        expect { filter.send(:object_link_filter, 'foo', %r{(?<!\w)}) }.to raise_error(NotImplementedError)
      end
    end
  end
end
