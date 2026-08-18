# frozen_string_literal: true

require 'fast_spec_helper'

# The docs name every key of a document the gem generates, so a gem release that
# adds one leaves them quietly wrong. Each table is introduced by
# ``Response attributes for `<path>`:``; the path is read from the markdown and
# resolved against the real document, so a new table is covered automatically.
RSpec.describe 'doc/api/glql.md', feature_category: :custom_dashboards_foundation do
  let(:markdown) do
    File.read(File.expand_path('../../../../doc/api/glql.md', __dir__))
  end

  let(:section) do
    markdown[/^## Retrieve the GLQL schema$(.*?)(?=^## )/m] ||
      raise('the "Retrieve the GLQL schema" section is gone; update this spec with it')
  end

  let(:document) { Analytics::Glql::Schema.document }

  def documented_keys(heading)
    table = section[/#{Regexp.escape(heading)}\n\n((?:\|.*\n)+)/, 1]
    raise "no table found after #{heading.inspect}" if table.nil?

    keys = table.scan(/^\|\s*`([a-z_]+)`/).flatten
    raise "no attribute rows found after #{heading.inspect}" if keys.empty?

    keys
  end

  # Union across entries: a key can be absent from any one of them, such as
  # `dimensions` on standard modes.
  def actual_keys(path)
    nodes = path.split('.').reduce([document]) do |current, step|
      name = step.delete_suffix('[]')
      current.flat_map { |node| Array.wrap(node[name]) }
    end

    nodes.flat_map(&:keys).uniq
  end

  it 'documents every top-level attribute, and no others' do
    expect(documented_keys('response attributes:')).to match_array(document.keys)
  end

  it 'has a table for every documented path' do
    paths = section.scan(/^Response attributes for `(.+?)`:$/).flatten

    expect(paths).not_to be_empty

    paths.each do |path|
      expect(documented_keys("Response attributes for `#{path}`:"))
        .to match_array(actual_keys(path)), "`#{path}` table does not match the document"
    end
  end

  it 'shows an example response the document could actually produce' do
    example = section[/^Example response, truncated:\n\n```json\n(.*?)^```/m, 1]
    expect(example).to be_present

    parsed = Gitlab::Json::SafeParser.parse(example)

    expect(parsed.keys).to all(be_in(document.keys))
    expect(parsed['version']).to eq(document['version'])
  end
end
