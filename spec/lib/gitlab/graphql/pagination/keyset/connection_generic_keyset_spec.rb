# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::Keyset::Connection do
  # https://gitlab.com/gitlab-org/gitlab/-/issues/334973
  # The spec will be merged with connection_spec.rb in the future.
  let(:nodes) { Project.all.order(id: :asc) }
  let(:arguments) { {} }
  let(:query_type) { GraphQL::ObjectType.new }
  let(:schema) { GraphQL::Schema.define(query: query_type, mutation: nil)}
  let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil, object: nil) }

  let_it_be(:column_order_id) { Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(attribute_name: 'id', order_expression: Project.arel_table[:id].asc) }
  let_it_be(:column_order_id_desc) { Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(attribute_name: 'id', order_expression: Project.arel_table[:id].desc) }
  let_it_be(:column_order_updated_at) { Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(attribute_name: 'updated_at', order_expression: Project.arel_table[:updated_at].asc) }
  let_it_be(:column_order_created_at) { Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(attribute_name: 'created_at', order_expression: Project.arel_table[:created_at].asc) }
  let_it_be(:column_order_last_repo) do
    Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
      attribute_name: 'last_repository_check_at',
      column_expression: Project.arel_table[:last_repository_check_at],
      order_expression: Gitlab::Database.nulls_last_order('last_repository_check_at', :asc),
      reversed_order_expression: Gitlab::Database.nulls_last_order('last_repository_check_at', :desc),
      order_direction: :asc,
      nullable: :nulls_last,
      distinct: false)
  end

  let_it_be(:column_order_last_repo_desc) do
    Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
      attribute_name: 'last_repository_check_at',
      column_expression: Project.arel_table[:last_repository_check_at],
      order_expression: Gitlab::Database.nulls_last_order('last_repository_check_at', :desc),
      reversed_order_expression: Gitlab::Database.nulls_last_order('last_repository_check_at', :asc),
      order_direction: :desc,
      nullable: :nulls_last,
      distinct: false)
  end

  subject(:connection) do
    described_class.new(nodes, **{ context: context, max_page_size: 3 }.merge(arguments))
  end

  def encoded_cursor(node)
    described_class.new(nodes, context: context).cursor_for(node)
  end

  def decoded_cursor(cursor)
    Gitlab::Json.parse(Base64Bp.urlsafe_decode64(cursor))
  end

  describe "With generic keyset order support" do
    let(:nodes) { Project.all.order(Gitlab::Pagination::Keyset::Order.build([column_order_id])) }

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

      context 'when an order is specified' do
        let(:nodes) { Project.all.order(Gitlab::Pagination::Keyset::Order.build([column_order_id])) }

        it 'returns the encoded value of the order' do
          expect(decoded_cursor(cursor)).to include('id' => project.id.to_s)
        end
      end

      context 'when multiple orders are specified' do
        let(:nodes) { Project.all.order(Gitlab::Pagination::Keyset::Order.build([column_order_updated_at, column_order_created_at, column_order_id])) }

        it 'returns the encoded value of the order' do
          expect(decoded_cursor(cursor)).to include('updated_at' => project.updated_at.strftime('%Y-%m-%d %H:%M:%S.%N %Z'))
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
          let(:nodes) { Project.all.order(Gitlab::Pagination::Keyset::Order.build([column_order_id_desc])) }

          it 'returns the correct nodes' do
            expect(subject.sliced_nodes).to contain_exactly(*projects[2..-1])
          end
        end
      end

      context 'when after is passed' do
        let(:arguments) { { after: encoded_cursor(projects[1]) } }

        it 'only returns the project before the selected one' do
          expect(subject.sliced_nodes).to contain_exactly(*projects[2..-1])
        end

        context 'when the sort order is descending' do
          let(:nodes) { Project.all.order(Gitlab::Pagination::Keyset::Order.build([column_order_id_desc])) }

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

      context 'when multiple orders with nil values are defined' do
        let_it_be(:project1) { create(:project, last_repository_check_at: 10.days.ago) }    # Asc: project5  Desc: project3
        let_it_be(:project2) { create(:project, last_repository_check_at: nil) }            # Asc: project1  Desc: project1
        let_it_be(:project3) { create(:project, last_repository_check_at: 5.days.ago) }     # Asc: project3  Desc: project5
        let_it_be(:project4) { create(:project, last_repository_check_at: nil) }            # Asc: project2  Desc: project2
        let_it_be(:project5) { create(:project, last_repository_check_at: 20.days.ago) }    # Asc: project4  Desc: project4

        context 'when ascending' do
          let_it_be(:order) { Gitlab::Pagination::Keyset::Order.build([column_order_last_repo, column_order_id]) }
          let_it_be(:nodes) { Project.order(order) }
          let_it_be(:ascending_nodes) { [project5, project1, project3, project2, project4] }

          it_behaves_like 'nodes are in ascending order'

          context 'when before cursor value is NULL' do
            let(:arguments) { { before: encoded_cursor(project4) } }

            it 'returns all projects before the cursor' do
              expect(subject.sliced_nodes).to eq([project5, project1, project3, project2])
            end
          end

          context 'when after cursor value is NULL' do
            let(:arguments) { { after: encoded_cursor(project2) } }

            it 'returns all projects after the cursor' do
              expect(subject.sliced_nodes).to eq([project4])
            end
          end
        end

        context 'when descending' do
          let_it_be(:order) { Gitlab::Pagination::Keyset::Order.build([column_order_last_repo_desc, column_order_id]) }
          let_it_be(:nodes) { Project.order(order) }
          let_it_be(:descending_nodes) { [project3, project1, project5, project2, project4] }

          it_behaves_like 'nodes are in descending order'

          context 'when before cursor value is NULL' do
            let(:arguments) { { before: encoded_cursor(project4) } }

            it 'returns all projects before the cursor' do
              expect(subject.sliced_nodes).to eq([project3, project1, project5, project2])
            end
          end

          context 'when after cursor value is NULL' do
            let(:arguments) { { after: encoded_cursor(project2) } }

            it 'returns all projects after the cursor' do
              expect(subject.sliced_nodes).to eq([project4])
            end
          end
        end
      end

      # rubocop: disable RSpec/EmptyExampleGroup
      context 'when ordering uses LOWER' do
      end
      # rubocop: enable RSpec/EmptyExampleGroup

      context 'when ordering by similarity' do
        let_it_be(:project1) { create(:project, name: 'test') }
        let_it_be(:project2) { create(:project, name: 'testing') }
        let_it_be(:project3) { create(:project, name: 'tests') }
        let_it_be(:project4) { create(:project, name: 'testing stuff') }
        let_it_be(:project5) { create(:project, name: 'test') }

        let_it_be(:nodes) do
          # Note: sorted_by_similarity_desc scope internally supports the generic keyset order.
          Project.sorted_by_similarity_desc('test', include_in_select: true)
        end

        let_it_be(:descending_nodes) { nodes.to_a }

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
      let_it_be(:nodes) { Project.order(Gitlab::Pagination::Keyset::Order.build([column_order_id])) }

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
end
