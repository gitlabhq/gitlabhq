# frozen_string_literal: true

RSpec.shared_examples 'a GraphQL type with labels' do
  it 'has label fields' do
    expected_fields = %w[label labels]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'label field' do
    subject { described_class.fields['label'] }

    it { is_expected.to have_graphql_type(Types::LabelType) }
    it { is_expected.to have_graphql_arguments(:title) }
  end

  describe 'labels field' do
    subject { described_class.fields['labels'] }

    it { is_expected.to have_graphql_type(Types::LabelType.connection_type) }
    it { is_expected.to have_graphql_arguments(:search_term) }
  end
end

RSpec.shared_examples 'querying a GraphQL type with labels' do
  let_it_be(:current_user) { create(:user) }

  let_it_be(:label_a) { create(label_factory, :described, **label_attrs) }
  let_it_be(:label_b) { create(label_factory, :described, **label_attrs) }
  let_it_be(:label_c) { create(label_factory, :described, :scoped, prefix: 'matching', **label_attrs) }
  let_it_be(:label_d) { create(label_factory, :described, :scoped, prefix: 'matching', **label_attrs) }

  let(:label_title) { label_b.title }

  let(:label_params) { { title: label_title } }
  let(:labels_params) { nil }

  let(:label_response) { graphql_data.dig(*path_prefix, 'label') }
  let(:labels_response) { graphql_data.dig(*path_prefix, 'labels', 'nodes') }

  let(:query) do
    make_query(
      [
        query_graphql_field(:label, label_params, all_graphql_fields_for(Label)),
        query_graphql_field(:labels, labels_params, [
          query_graphql_field(:nodes, nil, all_graphql_fields_for(Label))
        ])
      ]
    )
  end

  context 'running a query' do
    before do
      run_query(query)
    end

    context 'minimum required arguments' do
      it 'returns the label information' do
        expect(label_response).to include(
          'title' => label_title,
          'description' => label_b.description
        )
      end

      it 'returns the labels information' do
        expect(labels_response.pluck('title')).to contain_exactly(
          label_a.title,
          label_b.title,
          label_c.title,
          label_d.title
        )
      end
    end

    context 'with a search param' do
      let(:labels_params) { { search_term: 'matching' } }

      it 'finds the matching labels' do
        expect(labels_response.pluck('title')).to contain_exactly(
          label_c.title,
          label_d.title
        )
      end
    end

    context 'the label does not exist' do
      let(:label_title) { 'not-a-label' }

      it 'returns nil' do
        expect(label_response).to be_nil
      end
    end
  end

  describe 'performance' do
    def query_for(*labels)
      selections = labels.map do |label|
        %Q[#{label.title.gsub(/:+/, '_')}: label(title: "#{label.title}") { description }]
      end

      make_query(selections)
    end

    before do
      run_query(query_for(label_a))
    end

    it 'batches queries for labels by title' do
      pending('See: https://gitlab.com/gitlab-org/gitlab/-/issues/217767')

      multi_selection = query_for(label_b, label_c)
      single_selection = query_for(label_d)

      expect { run_query(multi_selection) }
        .to issue_same_number_of_queries_as { run_query(single_selection) }
    end
  end

  # Run a known good query with the current user
  def run_query(query)
    post_graphql(query, current_user: current_user)
    expect(graphql_errors).not_to be_present
  end
end
