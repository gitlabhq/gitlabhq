# frozen_string_literal: true

module AtomFeedHelpers
  def atom_rendered_link_hrefs(feed, selector = 'entry content')
    Nokogiri::XML(feed).tap(&:remove_namespaces!).css(selector).flat_map do |node|
      Nokogiri::HTML5.fragment(node.text).css('a.gfm').map { |link| link[:href] }
    end
  end
end
