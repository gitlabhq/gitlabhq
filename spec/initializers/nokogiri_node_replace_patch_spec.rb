# frozen_string_literal: true

require 'fast_spec_helper'
require 'nokogiri'

require_relative '../../config/initializers/nokogiri_node_replace_patch'

RSpec.describe 'nokogiri_node_replace_patch', feature_category: :markdown do
  let(:doc) { Nokogiri::HTML5.fragment('Document with text <strong>and element</strong>.') }
  let(:strong) { doc.at_css('strong') }

  shared_examples 'returns the nodes inserted into the document' do
    it 'returns nodes that are children of the document' do
      expect(replaced).to all(satisfy { |node| doc.children.include?(node) })
    end

    it 'returns nodes that remove themselves from the document' do
      replaced.each(&:remove)

      expect(doc.children.map(&:text)).to eq(['Document with text ', '.'])
    end
  end

  describe 'Nokogiri::XML::Node#replace' do
    context 'when replacing with a string containing text and elements' do
      subject(:replaced) { strong.replace('and <em>element</em>') }

      it 'returns the new text and element' do
        expect(replaced.map { |node| [node.name, node.text] }).to eq([['text', 'and '], %w[em element]])
      end

      it_behaves_like 'returns the nodes inserted into the document'
    end

    context 'when replacing with a string containing only text' do
      subject(:replaced) { strong.replace('and text') }

      it 'returns the new text' do
        expect(replaced.map { |node| [node.name, node.text] }).to eq([['text', 'and text']])
      end

      it_behaves_like 'returns the nodes inserted into the document'
    end

    context 'when replacing with a document fragment' do
      subject(:replaced) { strong.replace(doc.fragment('and <em>element</em>')) }

      it_behaves_like 'returns the nodes inserted into the document'
    end

    context 'when replacing a text node' do
      subject(:replaced) { text_node.replace('replaced <em>text</em>') }

      let(:doc) { Nokogiri::HTML5.fragment('<em>before</em>original<em>after</em>') }
      let(:text_node) { doc.children[1] }

      it 'returns the new text and element' do
        expect(replaced.map { |node| [node.name, node.text] }).to eq([['text', 'replaced '], %w[em text]])
      end

      it 'returns nodes that are children of the document' do
        expect(replaced).to all(satisfy { |node| doc.children.include?(node) })
      end

      it 'returns nodes that remove themselves from the document' do
        replaced.each(&:remove)

        expect(doc.children.map(&:text)).to eq(%w[before after])
      end
    end

    context 'when replacing with a single node' do
      subject(:replaced) { strong.replace(node) }

      let(:node) { Nokogiri::XML::Node.new('em', doc.document) }

      it 'returns the node' do
        expect(replaced).to be(node)
      end

      it 'replaces the node in the document' do
        replaced

        expect(doc.children.map(&:name)).to eq(%w[text em text])
      end
    end

    context 'when the node has no parent' do
      it 'raises an error' do
        strong.unlink

        expect { strong.replace('text') }.to raise_error(RuntimeError, 'Cannot replace a node with no parent')
      end
    end
  end

  describe 'unpatched Nokogiri::XML::Node#replace' do
    let(:unpatched_replace) do
      Nokogiri::XML::Node.instance_method(:replace).super_method.bind(strong)
    end

    it 'still returns text nodes that are not in the document' do
      replaced = unpatched_replace.call('and <em>element</em>')

      expect(doc.children).not_to include(replaced.first),
        'Nokogiri::XML::Node#replace is fixed upstream; remove config/initializers/nokogiri_node_replace_patch.rb'
    end
  end
end
