# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::JsonTableFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:table_with_fields) do
    <<~TEXT
      <pre data-canonical-lang="json" data-lang-params="table">
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
            "starts_at": "_2024-10-07_"
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
      <thead>
      <tr>
      <th>Date &lt; &amp; &gt;</th>
      <th>URL</th>
      </tr>
      </thead>
      <tbody>
      <tr>
      <td><em>2024-10-07</em></td>
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
      <thead>
      <tr>
      <th>starts_at</th>
      <th>url</th>
      </tr>
      </thead>
      <tbody>
      <tr>
      <td><em>2024-10-07</em></td>
      <td><a href="https://example.com/page2.html">https://example.com/page2.html</a></td>
      </tr>
      </tbody>
      </table></div>
    HTML
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
end
