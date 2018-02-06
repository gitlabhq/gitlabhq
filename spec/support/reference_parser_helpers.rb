module ReferenceParserHelpers
  def empty_html_link
    Nokogiri::HTML.fragment('<a></a>').children[0]
  end
end
