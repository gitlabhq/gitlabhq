# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::Keyset::Connection do
  include GraphqlHelpers

  let(:nodes) { Project.all.order(id: :asc) }
  let(:arguments) { {} }
  let(:context) { GraphQL::Query::Context.new(query: query_double, values: nil, object: nil) }

  subject(:connection) do
    described_class.new(nodes, **{ context: context, max_page_size: 3 }.merge(arguments))
  end

  def encoded_cursor(node)
    described_class.new(nodes, context: context).cursor_for(node)
  end

  def decoded_cursor(cursor)
    Gitlab::Json.parse(Base64Bp.urlsafe_decode64(cursor))
  end

  # see: https://gitlab.com/gitlab-org/gitlab/-/issues/297358
  context 'the relation has been preloaded' do
    let(:projects) { Project.all.preload(:issues) }
    let(:nodes) { projects.first.issues }

    before do
      project = create(:project)
      create_list(:issue, 3, project: project)
    end

    it 'is loaded' do
      expect(nodes).to be_loaded
    end

    it 'does not error when accessing pagination information' do
      connection.first = 2

      expect(connection).to have_attributes(
        has_previous_page: false,
        has_next_page: true
      )
    end

    it 'can generate cursors' do
      connection.send(:ordered_items) # necessary to generate the order-list

      expect(connection.cursor_for(nodes.first)).to be_a(String)
    end

    it 'can read the next page' do
      connection.send(:ordered_items) # necessary to generate the order-list
      ordered = nodes.reorder(id: :desc)
      next_page = described_class.new(nodes,
                                      context: context,
                                      max_page_size: 3,
                                      after: connection.cursor_for(ordered.second))

      expect(next_page.sliced_nodes).to contain_exactly(ordered.third)
    end
  end

  it_behaves_like 'a connection with collection methods'

  it_behaves_like 'a redactable connection' do
    let_it_be(:projects) { create_list(:project, 2) }
    let(:unwanted) { projects.second }
  end

  describe '#cursor_for' do
    let(:project) { create(:project) }
    let(:cursor)  { connection.cursor_for(project) }

    it 'returns an encoded ID' do
      expect(decoded_cursor(cursor)).to eq('id' => project.id.to_s)
    end

    context 'when SimpleOrderBuilder cannot build keyset paginated query' do
      it 'increments the `old_keyset_pagination_usage` counter', :prometheus do
        expect(Gitlab::Pagination::Keyset::SimpleOrderBuilder).to receive(:build).and_return([false, nil])

        decoded_cursor(cursor)

        counter = Gitlab::Metrics.registry.get(:old_keyset_pagination_usage)
        expect(counter.get(model: 'Project')).to eq(1)
      end
    end

    context 'when an order is specified' do
      let(:nodes) { Project.order(:updated_at) }

      it 'returns the encoded value of the order' do
        expect(decoded_cursor(cursor)).to include('updated_at' => project.updated_at.to_s(:inspect))
      end

      it 'includes the :id even when not specified in the order' do
        expect(decoded_cursor(cursor)).to include('id' => project.id.to_s)
      end
    end

    context 'when multiple orders are specified' do
      let(:nodes) { Project.order(:updated_at).order(:created_at) }

      it 'returns the encoded value of the order' do
        expect(decoded_cursor(cursor)).to include('updated_at' => project.updated_at.to_s(:inspect))
      end
    end

    context 'when multiple orders with SQL are specified' do
      let(:nodes) { Project.order(Arel.sql('projects.updated_at IS NULL')).order(:updated_at).order(:id) }

      it 'returns the encoded value of the order' do
        expect(decoded_cursor(cursor)).to include('updated_at' => project.updated_at.to_s(:inspect))
      end
    end
  end

  describe '#sliced_nodes' do
    let(:projects) { create_list(:project, 4) }

    context 'when before is passed' do
      let(:arguments) { { before: encoded_cursor(projects[1]) } }

      it 'only returns the project before the selected one' do
        expect(subject.sliced_nodes).to contain_exactly(projects.first)
      end

      context 'when the sort order is descending' do
        let(:nodes) { Project.all.order(id: :desc) }

        it 'returns the correct nodes' do
          expect(subject.sliced_nodes).to contain_exactly(*projects[2..])
        end
      end
    end

    context 'when after is passed' do
      let(:arguments) { { after: encoded_cursor(projects[1]) } }

      it 'only returns the project before the selected one' do
        expect(subject.sliced_nodes).to contain_exactly(*projects[2..])
      end

      context 'when the sort order is descending' do
        let(:nodes) { Project.all.order(id: :desc) }

        it 'returns the correct nodes' do
          expect(subject.sliced_nodes).to contain_exactly(projects.first)
        end
      end
    end

    context 'when both before and after are passed' do
      let(:arguments) do
        {
          after: encoded_cursor(projects[1]),
          before: encoded_cursor(projects[3])
        }
      end

      it 'returns the expected set' do
        expect(subject.sliced_nodes).to contain_exactly(projects[2])
      end
    end

    shared_examples 'nodes are in ascending order' do
      context 'when no cursor is passed' do
        let(:arguments) { {} }

        it 'returns projects in ascending order' do
          expect(subject.sliced_nodes).to eq(ascending_nodes)
        end
      end

      context 'when before cursor value is not NULL' do
        let(:arguments) { { before: encoded_cursor(ascending_nodes[2]) } }

        it 'returns all projects before the cursor' do
          expect(subject.sliced_nodes).to eq(ascending_nodes.first(2))
        end
      end

      context 'when after cursor value is not NULL' do
        let(:arguments) { { after: encoded_cursor(ascending_nodes[1]) } }

        it 'returns all projects after the cursor' do
          expect(subject.sliced_nodes).to eq(ascending_nodes.last(3))
        end
      end

      context 'when before and after cursor' do
        let(:arguments) { { before: encoded_cursor(ascending_nodes.last), after: encoded_cursor(ascending_nodes.first) } }

        it 'returns all projects after the cursor' do
          expect(subject.sliced_nodes).to eq(ascending_nodes[1..3])
        end
      end
    end

    shared_examples 'nodes are in descending order' do
      context 'when no cursor is passed' do
        let(:arguments) { {} }

        it 'only returns projects in descending order' do
          expect(subject.sliced_nodes).to eq(descending_nodes)
        end
      end

      context 'when before cursor value is not NULL' do
        let(:arguments) { { before: encoded_cursor(descending_nodes[2]) } }

        it 'returns all projects before the cursor' do
          expect(subject.sliced_nodes).to eq(descending_nodes.first(2))
        end
      end

      context 'when after cursor value is not NULL' do
        let(:arguments) { { after: encoded_cursor(descending_nodes[1]) } }

        it 'returns all projects after the cursor' do
          expect(subject.sliced_nodes).to eq(descending_nodes.last(3))
        end
      end

      context 'when before and after cursor' do
        let(:arguments) { { before: encoded_cursor(descending_nodes.last), after: encoded_cursor(descending_nodes.first) } }

        it 'returns all projects after the cursor' do
          expect(subject.sliced_nodes).to eq(descending_nodes[1..3])
        end
      end
    end

    context 'when ordering uses LOWER' do
      let!(:project1) { create(:project, name: 'A') } # Asc: project1  Desc: project4
      let!(:project2) { create(:project, name: 'c') } # Asc: project5  Desc: project2
      let!(:project3) { create(:project, name: 'b') } # Asc: project3  Desc: project3
      let!(:project4) { create(:project, name: 'd') } # Asc: project2  Desc: project5
      let!(:project5) { create(:project, name: 'a') } # Asc: project4  Desc: project1

      context 'when ascending' do
        let(:nodes) do
          Project.order(Arel::Table.new(:projects)['name'].lower.asc).order(id: :asc)
        end

        let(:ascending_nodes) { [project1, project5, project3, project2, project4] }

        it_behaves_like 'nodes are in ascending order'
      end

      context 'when descending' do
        let(:nodes) do
          Project.order(Arel::Table.new(:projects)['name'].lower.desc).order(id: :desc)
        end

        let(:descending_nodes) { [project4, project2, project3, project5, project1] }

        it_behaves_like 'nodes are in descending order'
      end
    end

    context 'NULLS order' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:issue1) { create(:issue, relative_position: nil) }
      let_it_be(:issue2) { create(:issue, relative_position: 100) }
      let_it_be(:issue3) { create(:issue, relative_position: 200) }
      let_it_be(:issue4) { create(:issue, relative_position: nil) }
      let_it_be(:issue5) { create(:issue, relative_position: 300) }

      context 'when ascending NULLS LAST (ties broken by id DESC implicitly)' do
        let(:ascending_nodes) { [issue2, issue3, issue5, issue4, issue1] }

        where(:nodes) do
          [
            lazy { Issue.order(Issue.arel_table[:relative_position].asc.nulls_last) }
          ]
        end

        with_them do
          it_behaves_like 'nodes are in ascending order'
        end
      end

      context 'when descending NULLS LAST (ties broken by id DESC implicitly)' do
        let(:descending_nodes) { [issue5, issue3, issue2, issue4, issue1] }

        where(:nodes) do
          [
            lazy { Issue.order(Issue.arel_table[:relative_position].desc.nulls_last) }
]
        end

        with_them do
          it_behaves_like 'nodes are in descending order'
        end
      end

      context 'when ascending NULLS FIRST with a tie breaker' do
        let(:ascending_nodes) { [issue1, issue4, issue2, issue3, issue5] }

        where(:nodes) do
          [
            lazy { Issue.order(Issue.arel_table[:relative_position].asc.nulls_first).order(id: :asc) }
]
        end

        with_them do
          it_behaves_like 'nodes are in ascending order'
        end
      end

      context 'when descending NULLS FIRST with a tie breaker' do
        let(:descending_nodes) { [issue1, issue4, issue5, issue3, issue2] }

        where(:nodes) do
          [
            lazy { Issue.order(Issue.arel_table[:relative_position].desc.nulls_first).order(id: :asc) }
]
        end

        with_them do
          it_behaves_like 'nodes are in descending order'
        end
      end
    end

    context 'when ordering by similarity' do
      let!(:project1) { create(:project, name: 'test') }
      let!(:project2) { create(:project, name: 'testing') }
      let!(:project3) { create(:project, name: 'tests') }
      let!(:project4) { create(:project, name: 'testing stuff') }
      let!(:project5) { create(:project, name: 'test') }

      let(:nodes) do
        Project.sorted_by_similarity_desc('test', include_in_select: true)
      end

      let(:descending_nodes) { nodes.to_a }

      it_behaves_like 'nodes are in descending order'
    end

    context 'when an invalid cursor is provided' do
      let(:arguments) { { before: Base64Bp.urlsafe_encode64('invalidcursor', padding: false) } }

      it 'raises an error' do
        expect { subject.sliced_nodes }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end
  end

  describe '#nodes' do
    let_it_be(:all_nodes) { create_list(:project, 5) }

    let(:paged_nodes) { subject.nodes }

    it_behaves_like 'connection with paged nodes' do
      let(:paged_nodes_size) { 3 }
    end

    context 'when both are passed' do
      let(:arguments) { { first: 2, last: 2 } }

      it 'raises an error' do
        expect { paged_nodes }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'when primary key is not in original order' do
      let(:nodes) { Project.order(last_repository_check_at: :desc) }

      before do
        stub_feature_flags(new_graphql_keyset_pagination: false)
      end

      it 'is added to end' do
        sliced = subject.sliced_nodes

        order_sql = sliced.order_values.last.to_sql

        expect(order_sql).to end_with(Project.arel_table[:id].desc.to_sql)
      end
    end

    context 'when there is no primary key' do
      before do
        stub_const('NoPrimaryKey', Class.new(ActiveRecord::Base))
        NoPrimaryKey.class_eval do
          self.table_name  = 'no_primary_key'
          self.primary_key = nil
        end
      end

      let(:nodes) { NoPrimaryKey.all }

      it 'raises an error' do
        expect(NoPrimaryKey.primary_key).to be_nil
        expect { subject.sliced_nodes }.to raise_error(ArgumentError, 'Relation must have a primary key')
      end
    end
  end

  describe '#has_previous_page and #has_next_page' do
    # using a list of 5 items with a max_page of 3
    let_it_be(:project_list) { create_list(:project, 5) }
    let_it_be(:nodes) { Project.order(:id) }

    context 'when default query' do
      let(:arguments) { {} }

      it 'has no previous, but a next' do
        expect(subject.has_previous_page).to be_falsey
        expect(subject.has_next_page).to be_truthy
      end
    end

    context 'when before is first item' do
      let(:arguments) { { before: encoded_cursor(project_list.first) } }

      it 'has no previous, but a next' do
        expect(subject.has_previous_page).to be_falsey
        expect(subject.has_next_page).to be_truthy
      end
    end

    describe 'using `before`' do
      context 'when before is the last item' do
        let(:arguments) { { before: encoded_cursor(project_list.last) } }

        it 'has no previous, but a next' do
          expect(subject.has_previous_page).to be_falsey
          expect(subject.has_next_page).to be_truthy
        end
      end

      context 'when before and last specified' do
        let(:arguments) { { before: encoded_cursor(project_list.last), last: 2 } }

        it 'has a previous and a next' do
          expect(subject.has_previous_page).to be_truthy
          expect(subject.has_next_page).to be_truthy
        end
      end

      context 'when before and last does request all remaining nodes' do
        let(:arguments) { { before: encoded_cursor(project_list[1]), last: 3 } }

        it 'has a previous and a next' do
          expect(subject.has_previous_page).to be_falsey
          expect(subject.has_next_page).to be_truthy
          expect(subject.nodes).to eq [project_list[0]]
        end
      end
    end

    describe 'using `after`' do
      context 'when after is the first item' do
        let(:arguments) { { after: encoded_cursor(project_list.first) } }

        it 'has a previous, and a next' do
          expect(subject.has_previous_page).to be_truthy
          expect(subject.has_next_page).to be_truthy
        end
      end

      context 'when after and first specified' do
        let(:arguments) { { after: encoded_cursor(project_list.first), first: 2 } }

        it 'has a previous and a next' do
          expect(subject.has_previous_page).to be_truthy
          expect(subject.has_next_page).to be_truthy
        end
      end

      context 'when before and last does request all remaining nodes' do
        let(:arguments) { { after: encoded_cursor(project_list[2]), last: 3 } }

        it 'has a previous but no next' do
          expect(subject.has_previous_page).to be_truthy
          expect(subject.has_next_page).to be_falsey
        end
      end
    end
  end
end
