# frozen_string_literal: true

# Requires `current_user`, `data_path`, `variables`, and `pagination_query(params)` bindings
RSpec.shared_examples 'sorted paginated variables' do
  subject(:expected_ordered_variables) { ordered_variables.map { |var| var.to_global_id.to_s } }

  context 'when sorted by key ascending' do
    let(:ordered_variables) { variables.sort_by(&:key) }

    it_behaves_like 'sorted paginated query' do
      let(:sort_param) { :KEY_ASC }
      let(:first_param) { 2 }
      let(:all_records) { expected_ordered_variables }
    end
  end

  context 'when sorted by key descending' do
    let(:ordered_variables) { variables.sort_by(&:key).reverse }

    it_behaves_like 'sorted paginated query' do
      let(:sort_param) { :KEY_DESC }
      let(:first_param) { 2 }
      let(:all_records) { expected_ordered_variables }
    end
  end
end
