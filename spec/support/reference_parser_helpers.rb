module ReferenceParserHelpers
  def empty_html_link
    Nokogiri::HTML.fragment('<a></a>').children[0]
  end

  shared_examples 'no N+1 queries' do
    it 'avoids N+1 queries in #nodes_visible_to_user', :request_store do
      record_queries = lambda do |links|
        ActiveRecord::QueryRecorder.new do
          described_class.new(project, user).nodes_visible_to_user(user, links)
        end
      end

      control = record_queries.call(control_links)
      actual = record_queries.call(actual_links)

      expect(actual.count).to be <= control.count
      expect(actual.cached_count).to be <= control.cached_count
    end

    it 'avoids N+1 queries in #records_for_nodes', :request_store do
      record_queries = lambda do |links|
        ActiveRecord::QueryRecorder.new do
          described_class.new(project, user).records_for_nodes(links)
        end
      end

      control = record_queries.call(control_links)
      actual = record_queries.call(actual_links)

      expect(actual.count).to be <= control.count
      expect(actual.cached_count).to be <= control.cached_count
    end
  end
end
