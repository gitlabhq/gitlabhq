# frozen_string_literal: true

# Assert that the two values are the same in HTML context, modulo escaping operations that
# do not change the meaning of the value --- i.e. do not change how a web browser or HTML parser
# would treat them.
#
# This means, e.g. '&quot;' and '"' are the same when encountered outside an HTML tag,
# but '&lt;b&gt;' and '<b>' are not.
#
# Likewise, '<a id="hello" href="#user-content-hello">' and
# "<a href='#user-content-hello' id=hello>" are considered the same.
#
# This matcher helps tests be less brittle or flakey in the face of changing attribute orders,
# and less repetitive in the face of comparing essentially unchanged values that nonetheless
# are represented differently.
#
# Note that it uses a real HTML parser internally so as not to introduce security issues
# through accidental de-escaping or any of the other myriad ways HTML can be messed with.
#
# ---
#
# The option "trim_text_nodes: true" can be given. This trims whitespace at the start and
# end of the text content of text nodes on each side. This should be used with care, but can
# aid in spec clarity by allowing expected DOMs to be written "prettified".
RSpec::Matchers.define :eq_html do |expected, **normalize_opts|
  include EqHtmlMatcher

  match do |actual|
    raise ArgumentError, "expected should be a String, not #{expected.class}" unless expected.is_a?(String)
    raise ArgumentError, "actual should be a String, not #{actual.class}" unless actual.is_a?(String)

    normalize_html(actual, **normalize_opts) == normalize_html(expected, **normalize_opts)
  end

  failure_message do |actual|
    "Expected that\n\n  #{actual}\n\nwould normalize to the same HTML as\n\n  #{expected}\n\nbut it didn't.\n\n  " \
      "#{normalize_html(actual, **normalize_opts).inspect}\n!=\n  " \
      "#{normalize_html(expected, **normalize_opts).inspect}"
  end

  failure_message_when_negated do |actual|
    "Expected that\n\n  #{actual}\n\nwould NOT normalize to the same HTML as\n\n  #{expected}\n\nbut it did!\n\n  " \
      "#{normalize_html(actual, **normalize_opts).inspect}\n==\n  " \
      "#{normalize_html(expected, **normalize_opts).inspect}"
  end
end

# Assert the right-hand value is contained in the left-hand value after normalising HTML on both sides per eq_html.
# See eq_html's docstring for details on what this means.
#
# Note this implies you can only check for inclusion of bare text (outside tags) and whole tags; a
# partial tag will normalise to text ("<strong" becomes "&lt;strong"), so you can't check that "<strong>"
# includes the HTML "<strong" --- it doesn't.  (If you really want to know that, you should probably instead
# parse the HTML with Nokogiri and check for the existence of a "strong" element.)
RSpec::Matchers.define :include_html do |expected|
  include EqHtmlMatcher

  match do |actual|
    raise ArgumentError, "expected should be a String, not #{expected.class}" unless expected.is_a?(String)
    raise ArgumentError, "actual should be a String, not #{actual.class}" unless actual.is_a?(String)

    normalize_html(actual).include? normalize_html(expected)
  end

  failure_message do |actual|
    "Expected that\n\n  #{actual}\n\nwould contain\n\n  #{expected}\n\nafter normalizing both, but it didn't.\n\n  " \
      "#{normalize_html(actual).inspect}\ndoesn't contain\n  " \
      "#{normalize_html(expected).inspect}"
  end

  failure_message_when_negated do |actual|
    "Expected that\n\n  #{actual}\n\nwould NOT contain\n\n  #{expected}\n\nafter normalizing both, but it did!\n\n  " \
      "#{normalize_html(actual).inspect}\nincludes\n  #{normalize_html(expected).inspect}"
  end
end

module EqHtmlMatcher
  def normalize_html(html, trim_text_nodes: false)
    doc = Nokogiri::HTML.fragment(html)
    doc.children.each { |n| normalize_node(n, trim_text_nodes:) }
    doc.to_html
  end

  def normalize_node(node, trim_text_nodes:)
    # Sort attributes by name so they normalise the same.
    attr_nodes = node.attributes.values.sort_by(&:name)
    attr_nodes.each(&:remove)
    attr_nodes.each do |attr|
      node[attr.name] = attr.value
    end

    node.content = node.content.strip if trim_text_nodes && node.text?

    node.children.each { |n| normalize_node(n, trim_text_nodes:) }
  end
end
