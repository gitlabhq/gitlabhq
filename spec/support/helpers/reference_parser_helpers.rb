# frozen_string_literal: true

module ReferenceParserHelpers
  def empty_html_link
    Nokogiri::HTML.fragment('<a></a>').children[0]
  end

  def expect_gathered_references(result, visible, nodes, visible_nodes)
    expect(result[:visible]).to eq(visible)
    expect(result[:nodes]).to eq(nodes)
    expect(result[:visible_nodes]).to eq(visible_nodes)
  end

  RSpec.shared_examples 'no project N+1 queries' do
    it 'avoids N+1 queries in #nodes_visible_to_user', :use_sql_query_cache do
      context = Banzai::RenderContext.new(project, user)

      request = ->(links) do
        described_class.new(context).nodes_visible_to_user(user, links)
      end

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { request.call(control_links) }

      create(:group_member, group: project.group) if project.group
      create(:project_member, project: project)
      create(:project_group_link, project: project)

      expect { request.call(actual_links) }.not_to exceed_query_limit(control)
    end
  end

  RSpec.shared_examples 'no N+1 queries' do
    it_behaves_like 'no project N+1 queries'

    it 'avoids N+1 queries in #records_for_nodes', :request_store do
      context = Banzai::RenderContext.new(project, user)

      record_queries = ->(links) do
        ActiveRecord::QueryRecorder.new do
          described_class.new(context).records_for_nodes(links)
        end
      end

      control = record_queries.call(control_links)
      actual = record_queries.call(actual_links)

      expect(actual.count).to be <= control.count
      expect(actual.cached_count).to be <= control.cached_count
    end
  end
end
