# frozen_string_literal: true

require 'rspec'
require 'ipynbdiff'
require 'json'
require 'rspec-parameterized'

TRANSFORMER_BASE_PATH = File.join(File.expand_path(File.dirname(__FILE__)),  'testdata')

def read_file(*paths)
  File.read(File.join(TRANSFORMER_BASE_PATH, *paths))
end

def default_config
  @default_config ||= {
    include_frontmatter: false,
    hide_images: false
  }
end

def from_ipynb
  @from_ipynb ||= read_file('from.ipynb')
end

def read_notebook(input_path)
  read_file(input_path, 'input.ipynb')
rescue Errno::ENOENT
  from_ipynb
end

describe IpynbDiff::Transformer do
  describe 'When notebook is valid' do
    using RSpec::Parameterized::TableSyntax

    where(:ctx, :test_case, :config) do
      'renders metadata' | 'no_cells' | { include_frontmatter: true }
      'is empty for no cells, but metadata is false' | 'no_cells_no_metadata' | {}
      'adds markdown cell' | 'only_md' | {}
      'adds block with only one line of markdown' | 'single_line_md' | {}
      'adds raw block' | 'only_raw' | {}
      'code cell, but no output' | 'only_code' | {}
      'code cell, but no language' | 'only_code_no_language' | {}
      'code cell, but no kernelspec' | 'only_code_no_kernelspec' | {}
      'code cell, but no nb metadata' | 'only_code_no_metadata' | {}
      'text output' | 'text_output' | {}
      'ignores html output' | 'ignore_html_output' | {}
      'extracts png output along with text' | 'text_png_output' | {}
      'embeds svg as image' | 'svg' | {}
      'extracts latex output' | 'latex_output'  | {}
      'extracts error output' | 'error_output'  | {}
      'does not fetch tags if there is no cell metadata' | 'no_metadata_on_cell' | {}
      'generates :percent decorator' | 'percent_decorator' | {}
      'parses stream output' | 'stream_text' | {}
      'ignores unknown output type' | 'unknown_output_type' | {}
      'handles backslash correctly' | 'backslash_as_last_char' | {}
      'multiline png output' | 'multiline_png_output' | {}
      'hides images when option passed' | 'hide_images' | { hide_images: true }
      '\n within source lines' | 'source_with_linebreak' | { hide_images: true }
    end

    with_them do
      let(:expected_md) { read_file(test_case, 'expected.md') }
      let(:expected_symbols) { read_file(test_case, 'expected_symbols.txt') }
      let(:input) { read_notebook(test_case) }
      let(:transformed) { IpynbDiff::Transformer.new(**default_config.merge(config)).transform(input) }

      it 'generates the expected markdown' do
        expect(transformed.as_text).to eq expected_md
      end

      it 'marks the lines correctly' do
        blocks = transformed.blocks.map { |b| b[:source_symbol] }.join("\n")
        result = expected_symbols

        expect(blocks).to eq result
      end
    end
  end

  it 'generates the correct transformed to source line map' do
    input = read_file('text_png_output', 'input.ipynb' )
    expected_line_numbers = read_file('text_png_output', 'expected_line_numbers.txt' )

    transformed = IpynbDiff::Transformer.new(**{ include_frontmatter: false }).transform(input)

    line_numbers = transformed.blocks.map { |b| b[:source_line] }.join("\n")

    expect(line_numbers).to eq(expected_line_numbers)

  end

  context 'When the notebook is invalid' do
    [
      ['because the json is invalid', 'a'],
      ['because it doesnt have the cell tag', '{"metadata":[]}']
    ].each do |ctx, notebook|
      context ctx do
        it 'raises error' do
          expect do
            IpynbDiff::Transformer.new.transform(notebook)
          end.to raise_error(IpynbDiff::InvalidNotebookError)
        end
      end
    end

    context 'when notebook can not be parsed' do
      it 'raises error' do
        notebook = '{"cells":[]}'
        allow(Oj::Parser.usual).to receive(:parse).and_return(nil)

        expect do
          IpynbDiff::Transformer.new.transform(notebook)
        end.to raise_error(IpynbDiff::InvalidNotebookError)
      end
    end
  end
end
