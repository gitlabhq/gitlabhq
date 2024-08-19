# frozen_string_literal: true

# Requires `issuables`, `field_name`, container_name`, and `container` bindings
RSpec.shared_examples 'issuables pagination and count' do
  let_it_be(:now) { Time.now.change(usec: 0) }
  let(:count_path) { ['data', container_name, field_name, 'count'] }
  let(:per_page) { nil }
  let(:page_size) { 3 }
  let(:query) do
    <<~GRAPHQL
      query #{container_name}($fullPath: ID!, $first: Int, $after: String) {
        #{container_name}(fullPath: $fullPath) {
          #{field_name}(first: $first, after: $after) {
            count
            edges {
              node {
                iid
              }
            }
            pageInfo {
              endCursor
              hasNextPage
            }
          }
        }
      }
    GRAPHQL
  end

  subject do
    GitlabSchema.execute(
      query,
      context: { current_user: user },
      variables: {
        fullPath: container.full_path,
        first: page_size
      }
    ).to_h
  end

  context 'when user does not have the permission' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :"read_#{container_name}", container).and_return(false)
    end

    it 'does not return an error' do
      expect(subject['errors']).to be_nil
    end

    it 'returns no data' do
      expect(subject['data'][container_name]).to be_nil
    end
  end

  context 'with count field' do
    let(:end_cursor) { ['data', container_name, field_name, 'pageInfo', 'endCursor'] }
    let(:issuables_edges) { ['data', container_name, field_name, 'edges'] }

    it 'returns total count' do
      expect(subject.dig(*count_path)).to eq(issuables.count)
    end

    it 'total count does not change between pages' do
      old_count = subject.dig(*count_path)
      new_cursor = subject.dig(*end_cursor)

      new_page = GitlabSchema.execute(
        query,
        context: { current_user: user },
        variables: {
          fullPath: container.full_path,
          first: page_size,
          after: new_cursor
        }
      ).to_h

      new_count = new_page.dig(*count_path)
      expect(old_count).to eq(new_count)
    end

    context 'with pagination' do
      let(:page_size) { per_page || 9 }

      it 'returns new ids during pagination' do
        old_edges = subject.dig(*issuables_edges)
        new_cursor = subject.dig(*end_cursor)

        new_edges = GitlabSchema.execute(
          query,
          context: { current_user: user },
          variables: {
            fullPath: container.full_path,
            first: page_size,
            after: new_cursor
          }
        ).to_h.dig(*issuables_edges)

        expect(old_edges.count).to eq(page_size)
        expect(new_edges.count).to eq(1)
      end
    end
  end
end
