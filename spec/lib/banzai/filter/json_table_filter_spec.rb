# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::JsonTableFilter, feature_category: :markdown do
  include FilterSpecHelper

  def json_table_input(data)
    pre = Nokogiri::HTML.parse('<pre>').at_css('pre')
    pre['data-canonical-lang'] = 'json'
    pre['data-lang-params'] = 'table'

    code = pre.document.create_element('code')
    pre << code
    code.content = data.to_json

    pre.to_html
  end

  let_it_be(:table_with_fields) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table another_param">
      <code>
      {
        "fields": [
          {
            "key": "starts_at",
            "label": "Date < & >",
            "sortable": true
          },
          {
            "key": "url",
            "label": "URL"
          }
        ],
        "items": [
          {
            "starts_at": "_2024-10-07_ :white_check_mark: 👍"
          },
          {
            "url": "https://example.com/page2.html"
          }
        ],
        "filter": true,
        "caption": "Markdown enabled table",
        "markdown": true
      }
      </code>
      </pre>
    TEXT
  end

  let_it_be(:table_with_fields_html) do
    <<~HTML
      <div><table data-table-fields='[{"key":"starts_at","label":"Date \\u003c \\u0026 \\u003e","sortable":true},{"key":"url","label":"URL"}]' data-table-filter="true" data-table-markdown="true">
      <caption><p>Markdown enabled table</p></caption>
      <thead><tr>
      <th>Date &lt; &amp; &gt;</th>
      <th>URL</th>
      </tr></thead>
      <tbody>
      <tr>
      <td>
      <em>2024-10-07</em> :white_check_mark: 👍</td>
      <td></td>
      </tr>
      <tr>
      <td></td>
      <td><a href="https://example.com/page2.html">https://example.com/page2.html</a></td>
      </tr>
      </tbody>
      </table></div>
    HTML
  end

  let_it_be(:table_without_fields) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
      <code>
      {
        "items": [
          {
            "starts_at": "_2024-10-07_",
            "url": "https://example.com/page2.html"
          }
        ],
        "markdown": true
      }
      </code>
      </pre>
    TEXT
  end

  let_it_be(:table_without_fields_html) do
    <<~HTML
      <div><table data-table-fields='[{"key":"starts_at"},{"key":"url"}]' data-table-markdown="true">
      <thead><tr>
      <th>starts_at</th>
      <th>url</th>
      </tr></thead>
      <tbody><tr>
      <td><em>2024-10-07</em></td>
      <td><a href="https://example.com/page2.html">https://example.com/page2.html</a></td>
      </tr></tbody>
      </table></div>
    HTML
  end

  let_it_be(:table_without_items) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
      <code>
      {
        "markdown": true
      }
      </code>
      </pre>
    TEXT
  end

  let_it_be(:table_with_invalid_items) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
      <code>
      {
        "items": ["wrong", {"format": null}],
        "markdown": true
      }
      </code>
      </pre>
    TEXT
  end

  let_it_be(:table_no_markdown) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
      <code>
      {
        "items": [
          {
            "starts_at": "_2024-10-07_",
            "url": "https://example.com/page2.html"
          }
        ]
      }
      </code>
      </pre>
    TEXT
  end

  let_it_be(:table_invalid_json) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
      <code>
      {
          {
            "starts_at": "_2024-10-07_",
            "url": "https://example.com/page2.html"
          }
        ],
        "markdown": true
      }
      </code>
      </pre>
    TEXT
  end

  let_it_be(:table_json_not_hash) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
      <code>
      []
      </code>
      </pre>
    TEXT
  end

  context 'when fields are provided' do
    it 'generates the correct HTML' do
      expect(filter(table_with_fields).to_html).to eq table_with_fields_html
    end
  end

  context 'when fields are not provided' do
    it 'generates the correct HTML' do
      expect(filter(table_without_fields).to_html).to eq table_without_fields_html
    end
  end

  context 'when items are not provided' do
    it 'does not change the HTML' do
      expect(filter(table_without_items).to_html).to eq table_without_items
    end
  end

  context 'when item format is invalid' do
    it 'does not change the HTML' do
      expect(filter(table_with_invalid_items).to_html).to eq table_with_invalid_items
    end
  end

  context 'when markdown is not enabled' do
    it 'does not change the HTML' do
      expect(filter(table_no_markdown).to_html).to eq table_no_markdown
    end
  end

  context 'when json is invalid' do
    it 'does not change the HTML' do
      expect(filter(table_invalid_json).to_html).to eq table_invalid_json
    end
  end

  context 'when json is not a hash' do
    it 'does not change the HTML' do
      expect(filter(table_json_not_hash).to_html).to eq table_json_not_hash
    end
  end

  context 'when json violates safe parsing limits' do
    let(:deep_json) do
      nested = '"value"'
      33.times { nested = %({ "a": #{nested} }) }

      <<~TEXT
        <pre data-canonical-lang="json" data-lang-params="table">
          <code>
            #{nested}
          </code>
        </pre>
      TEXT
    end

    it 'does not raise and does not change the HTML' do
      expect { filter(deep_json).to_html }.not_to raise_error
      expect(filter(deep_json).to_html).to eq deep_json
    end
  end

  context 'when items is an empty array' do
    it 'does not change the HTML' do
      input = json_table_input("items" => [], "markdown" => true)

      expect(filter(input).to_html).to eq input
    end
  end

  context 'when cell data contains pipe characters' do
    it 'renders pipes within a single cell' do
      input = json_table_input(
        "fields" => [{ "key" => "cmd" }],
        "items" => [{ "cmd" => "a | b | c" }],
        "markdown" => true
      )
      doc = filter(input)

      expect(doc.css('td').count).to eq 1
      expect(doc.at_css('td').text).to include('a | b | c')
    end
  end

  context 'when cell data contains newlines' do
    it 'renders newlines within a single cell' do
      input = json_table_input(
        "fields" => [{ "key" => "desc" }],
        "items" => [{ "desc" => "line1\nline2" }],
        "markdown" => true
      )
      doc = filter(input)

      expect(doc.css('tr').count).to eq 2 # 1 thead tr + 1 tbody tr
      expect(doc.css('td').count).to eq 1 # the header is a th!
      expect(doc.at_css('td').text).to include('line1')
      expect(doc.at_css('td').text).to include('line2')
    end
  end

  context 'when field labels contain special characters' do
    it 'escapes them as text content in header cells' do
      input = json_table_input(
        "fields" => [{ "key" => "a", "label" => "Date < & > <img>" }],
        "items" => [{ "a" => "b" }],
        "markdown" => true
      )
      doc = filter(input)

      expect(doc.at_css('th').text).to eq 'Date < & > <img>'
    end
  end

  context 'when a cell produces a single paragraph' do
    it 'unwraps the paragraph contents into the td' do
      input = json_table_input(
        "fields" => [{ "key" => "a" }],
        "items" => [{ "a" => "hello **world**" }],
        "markdown" => true
      )
      doc = filter(input)

      td = doc.at_css('td')
      expect(td.at_css('p')).to be_nil
      expect(td.at_css('strong').text).to eq 'world'
    end
  end

  context 'when a cell produces multiple paragraphs' do
    it 'retains the paragraph elements' do
      input = json_table_input(
        "fields" => [{ "key" => "a" }],
        "items" => [{ "a" => "para1\n\npara2" }],
        "markdown" => true
      )
      doc = filter(input)

      td = doc.at_css('td')
      expect(td.css('p').count).to eq 2
      expect(td.css('p').map(&:text)).to eq %w[para1 para2]
    end
  end

  context 'when fields contain extra keys beyond key/label/sortable' do
    it 'includes extra keys in data-table-fields at this stage' do
      # These are removed by SanitizationFilter.
      # Doing extra filtering here would be meaningless, as anything we remove a user could
      # simply enter directly!
      input = json_table_input(
        "fields" => [{ "key" => "a", "label" => "A", "class" => "evil", "thClass" => "bad" }],
        "items" => [{ "a" => "val" }],
        "markdown" => true
      )
      doc = filter(input)

      fields_json = doc.at_css('table')['data-table-fields']
      fields = Gitlab::Json.safe_parse(fields_json)
      expect(fields.first).to include('class' => 'evil', 'thClass' => 'bad')
    end
  end

  context 'when field label is not provided' do
    it 'falls back to the key for the header' do
      input = json_table_input(
        "fields" => [{ "key" => "my_field" }],
        "items" => [{ "my_field" => "val" }],
        "markdown" => true
      )
      doc = filter(input)

      expect(doc.at_css('th').text).to eq 'my_field'
    end
  end

  context 'when items are missing values for some fields' do
    it 'produces empty td elements for missing keys' do
      input = json_table_input(
        "fields" => [{ "key" => "a" }, { "key" => "b" }, { "key" => "c" }],
        "items" => [{ "a" => "present", "c" => "here" }],
        "markdown" => true
      )
      doc = filter(input)

      tds = doc.css('td')
      expect(tds.count).to eq 3
      expect(tds[0].text.strip).to eq 'present'
      expect(tds[1].text.strip).to eq ''
      expect(tds[2].text.strip).to eq 'here'
    end
  end

  context 'when data-table attributes are set' do
    it 'sets data-table-filter and data-table-markdown when enabled' do
      input = json_table_input(
        "fields" => [{ "key" => "a" }],
        "items" => [{ "a" => "val" }],
        "filter" => true,
        "markdown" => true
      )
      doc = filter(input)

      table = doc.at_css('table')
      expect(table['data-table-filter']).to eq 'true'
      expect(table['data-table-markdown']).to eq 'true'
    end

    it 'omits data-table-filter when filter is not set' do
      input = json_table_input(
        "fields" => [{ "key" => "a" }],
        "items" => [{ "a" => "val" }],
        "markdown" => true
      )
      doc = filter(input)

      table = doc.at_css('table')
      expect(table['data-table-filter']).to be_nil
      expect(table['data-table-markdown']).to eq 'true'
    end
  end

  context 'when the code node has no grandparent' do
    it 'does not transform the node' do
      doc = Nokogiri::HTML.fragment('')
      code = doc.document.create_element('code')
      code.content = '{"items":[{"a":"b"}],"markdown":true}'
      pre = doc.document.create_element('pre')
      pre['data-canonical-lang'] = 'json'
      pre['data-lang-params'] = 'table'
      pre << code

      instance = described_class.new(doc, {})
      instance.send(:process_json_table, code)

      expect(pre.parent).to be_nil
      expect(code.text).to eq '{"items":[{"a":"b"}],"markdown":true}'
    end
  end

  context 'when the code node has no parent' do
    it 'does not transform the node' do
      doc = Nokogiri::HTML.fragment('')
      code = doc.document.create_element('code')
      code.content = '{"items":[{"a":"b"}],"markdown":true}'

      instance = described_class.new(doc, {})
      instance.send(:process_json_table, code)

      expect(code.parent).to be_nil
    end
  end

  context 'when fields is a non-array value' do
    it 'does not change the HTML' do
      input = json_table_input(
        "fields" => "not_an_array",
        "items" => [{ "a" => "b" }],
        "markdown" => true
      )

      expect(filter(input).to_html).to eq input
    end
  end

  context 'when fields contains non-hash entries' do
    it 'does not change the HTML' do
      input = json_table_input(
        "fields" => [1, 2, 3],
        "items" => [{ "a" => "b" }],
        "markdown" => true
      )

      expect(filter(input).to_html).to eq input
    end
  end

  describe Banzai::Filter::JsonTableFilter::Input do
    describe '.parse' do
      it 'returns nil for non-JSON input' do
        expect(described_class.parse('not json')).to be_nil
      end

      it 'returns nil for JSON arrays' do
        expect(described_class.parse('[]')).to be_nil
      end

      it 'returns nil when markdown is not set' do
        expect(described_class.parse('{"items": [{"a": "b"}]}')).to be_nil
      end

      it 'returns nil for empty items array' do
        expect(described_class.parse('{"items": [], "markdown": true}')).to be_nil
      end

      it 'returns nil when items contains non-hashes' do
        expect(described_class.parse('{"items": ["wrong"], "markdown": true}')).to be_nil
      end

      it 'returns nil when items is not provided' do
        expect(described_class.parse('{"markdown": true}')).to be_nil
      end

      it 'returns nil when fields is not an array' do
        expect(described_class.parse('{"fields": "bad", "items": [{"a": "b"}], "markdown": true}')).to be_nil
      end

      it 'returns nil when fields contains non-hash entries' do
        expect(described_class.parse('{"fields": [1, 2], "items": [{"a": "b"}], "markdown": true}')).to be_nil
      end

      it 'infers fields from first item keys when fields not provided' do
        input = described_class.parse('{"items": [{"x": "1", "y": "2"}], "markdown": true}')

        expect(input.fields).to eq [{ 'key' => 'x' }, { 'key' => 'y' }]
      end

      it 'preserves explicitly provided fields' do
        json = '{"fields": [{"key": "a", "label": "A", "sortable": true}], "items": [{"a": "1"}], "markdown": true}'
        input = described_class.parse(json)

        expect(input.fields).to eq [{ 'key' => 'a', 'label' => 'A', 'sortable' => true }]
      end

      it 'exposes caption, filter, and markdown attributes' do
        json = '{"items": [{"a": "1"}], "markdown": true, "filter": true, "caption": "My Table"}'
        input = described_class.parse(json)

        expect(input.markdown).to be true
        expect(input.filter).to be true
        expect(input.caption).to eq 'My Table'
      end
    end
  end
end
