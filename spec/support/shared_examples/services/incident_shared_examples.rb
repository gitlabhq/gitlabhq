# frozen_string_literal: true

# This shared_example requires the following variables:
# - issue (required)
#
# Usage:
#
#   it_behaves_like 'incident issue' do
#     let(:issue) { ... }
#   end
#
#   include_examples 'incident issue'
RSpec.shared_examples 'incident issue' do
  let(:label_properties) { attributes_for(:label, :incident) }

  it 'has incident as issue type' do
    expect(issue.issue_type).to eq('incident')
  end

  it 'has exactly one incident label' do
    expect(issue.labels).to be_one do |label|
      label.slice(*label_properties.keys).symbolize_keys == label_properties
    end
  end
end

# This shared_example requires the following variables:
# - issue (required)
#
# Usage:
#
#   it_behaves_like 'not an incident issue' do
#     let(:issue) { ... }
#   end
#
#   include_examples 'not an incident issue'
RSpec.shared_examples 'not an incident issue' do
  let(:label_properties) { attributes_for(:label, :incident) }

  it 'has not incident as issue type' do
    expect(issue.issue_type).not_to eq('incident')
  end

  it 'has not an incident label' do
    expect(issue.labels).not_to include(have_attributes(label_properties))
  end
end
