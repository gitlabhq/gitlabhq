# frozen_string_literal: true

require 'spec_helper'

RSpec.context Kramdown::Parser::AtlassianDocumentFormat do
  let_it_be(:options) { { input: 'AtlassianDocumentFormat', html_tables: true } }
  let_it_be(:fixtures_path) { 'lib/kramdown/atlassian_document_format' }

  context 'markdown render' do
    shared_examples 'render elements to markdown' do |base_name|
      let(:json_file)     { "#{base_name}.json" }
      let(:markdown_file) { "#{base_name}.md" }

      it "renders #{base_name}" do
        source = fixture_file(File.join(fixtures_path, json_file))
        target = fixture_file(File.join(fixtures_path, markdown_file))
        parser = Kramdown::Document.new(source, options)

        expect(parser.to_commonmark).to eq target
      end
    end

    it_behaves_like 'render elements to markdown', 'blockquote'
    it_behaves_like 'render elements to markdown', 'bullet_list'
    it_behaves_like 'render elements to markdown', 'code_block'
    it_behaves_like 'render elements to markdown', 'emoji'
    it_behaves_like 'render elements to markdown', 'hard_break'
    it_behaves_like 'render elements to markdown', 'heading'
    it_behaves_like 'render elements to markdown', 'inline_card'
    it_behaves_like 'render elements to markdown', 'media_group'
    it_behaves_like 'render elements to markdown', 'media_single'
    it_behaves_like 'render elements to markdown', 'mention'
    it_behaves_like 'render elements to markdown', 'ordered_list'
    it_behaves_like 'render elements to markdown', 'panel'
    it_behaves_like 'render elements to markdown', 'paragraph'
    it_behaves_like 'render elements to markdown', 'rule'
    it_behaves_like 'render elements to markdown', 'table'

    it_behaves_like 'render elements to markdown', 'strong_em_mark'
    it_behaves_like 'render elements to markdown', 'code_mark'
    it_behaves_like 'render elements to markdown', 'link_mark'
    it_behaves_like 'render elements to markdown', 'strike_sup_sub_mark'
    it_behaves_like 'render elements to markdown', 'underline_text_color_mark'

    it_behaves_like 'render elements to markdown', 'complex_document'

    it 'renders header id to html' do
      source = fixture_file(File.join(fixtures_path, 'heading.json'))
      parser = Kramdown::Document.new(source, options)

      expect(parser.to_html).to include('id="header-2"')
    end

    it 'logs an error with invalid json' do
      source = fixture_file(File.join(fixtures_path, 'invalid_json.json'))

      expect(Gitlab::AppLogger).to receive(:error).with(/Invalid Atlassian Document Format JSON/)
      expect(Gitlab::AppLogger).to receive(:error).with(any_args)
      expect { Kramdown::Document.new(source, options) }.to raise_error(::Kramdown::Error, /Invalid Atlassian Document Format JSON/)
    end

    it 'logs an error if no valid document node' do
      source = fixture_file(File.join(fixtures_path, 'invalid_no_doc.json'))

      expect(Gitlab::AppLogger).to receive(:error).with(/Invalid Atlassian Document Format JSON/)
      expect(Gitlab::AppLogger).to receive(:error).with(any_args)
      expect { Kramdown::Document.new(source, options) }.to raise_error(::Kramdown::Error, /Invalid Atlassian Document Format JSON/)
    end

    it 'invalid node gets ignored' do
      source = fixture_file(File.join(fixtures_path, 'invalid_node_type.json'))
      parser = Kramdown::Document.new(source, options)

      expect(parser.to_commonmark).to eq "This is a second paragraph\n\n"
    end
  end
end
