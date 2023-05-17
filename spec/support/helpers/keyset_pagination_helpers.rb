# frozen_string_literal: true

module KeysetPaginationHelpers
  def pagination_links(response)
    link = response.headers['LINK']
    return unless link

    link.split(',').filter_map do |link|
      match = link.match(/<(?<url>.*)>; rel="(?<rel>\w+)"/)
      next unless match

      { url: match[:url], rel: match[:rel] }
    end
  end

  def pagination_params_from_next_url(response)
    next_link = pagination_links(response).find { |link| link[:rel] == 'next' }
    next_url = next_link&.fetch(:url)
    return unless next_url

    Rack::Utils.parse_query(URI.parse(next_url).query)
  end
end
