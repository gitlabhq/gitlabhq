# frozen_string_literal: true

# Manually filter EE types instead of extending the examples table
# to make the shared examples work on both FOSS/EE and
# to avoid to make the table even more complex
def filter_ee(types)
  return types if Gitlab.ee?

  expected_types.difference(::WorkItems::Type::EE_BASE_TYPES)
end

# rubocop:disabled Layout/LineLength -- in this case it's easier to read as a large table
RSpec.shared_examples_for 'allowed work item types for a project' do
  using RSpec::Parameterized::TableSyntax

  where(:service_desk, :okrs, :project_work_item_epics, :epics_license, :expected_types) do
    false | false | false | false | %w[incident issue task]
    false | false | false | true | %w[incident issue task]
    false | false | true | false | %w[incident issue task]
    false | false | true | true | %w[epic incident issue task]
    false | true | false | false | %w[incident issue key_result objective task]
    false | true | false | true | %w[incident issue key_result objective task]
    false | true | true | false | %w[incident issue key_result objective task]
    false | true | true | true | %w[epic incident issue key_result objective task]
    true | false | false | false | %w[incident issue task ticket]
    true | false | false | true | %w[incident issue task ticket]
    true | false | true | false | %w[incident issue task ticket]
    true | false | true | true | %w[epic incident issue task ticket]
    true | true | false | false | %w[incident issue key_result objective task ticket]
    true | true | false | true | %w[incident issue key_result objective task ticket]
    true | true | true | false | %w[incident issue key_result objective task ticket]
    true | true | true | true | %w[epic incident issue key_result objective task ticket]
    false | false | false | false | %w[incident issue task]
    false | false | false | true | %w[incident issue task]
    false | false | true | false | %w[incident issue task]
    false | false | true | true | %w[epic incident issue task]
    false | true | false | false | %w[incident issue key_result objective task]
    false | true | false | true | %w[incident issue key_result objective task]
    false | true | true | false | %w[incident issue key_result objective task]
    false | true | true | true | %w[epic incident issue key_result objective task]
    true | false | false | false | %w[incident issue task ticket]
    true | false | false | true | %w[incident issue task ticket]
    true | false | true | false | %w[incident issue task ticket]
    true | false | true | true | %w[epic incident issue task ticket]
    true | true | false | false | %w[incident issue key_result objective task ticket]
    true | true | false | true | %w[incident issue key_result objective task ticket]
    true | true | true | false | %w[incident issue key_result objective task ticket]
    true | true | true | true | %w[epic incident issue key_result objective task ticket]
  end

  with_them do
    before do
      stub_feature_flags(
        service_desk_ticket: service_desk,
        okrs_mvc: okrs,
        project_work_item_epics: project_work_item_epics
      )
      stub_licensed_features(epics: epics_license)
    end

    it 'returns only the allowed work item base types' do
      expect(types_list).to eq(filter_ee(expected_types))
    end
  end
end

RSpec.shared_examples_for 'allowed work item types for a group' do
  using RSpec::Parameterized::TableSyntax

  where(:epics_license, :expected_types) do
    false | %w[]
    true | %w[epic]
  end

  with_them do
    before do
      stub_licensed_features(epics: epics_license)
    end

    it 'returns only the allowed work item base types' do
      expect(types_list).to eq(filter_ee(expected_types))
    end
  end
end

RSpec.shared_examples 'lists all work item type values' do
  specify do
    expect(types_list).to eq(WorkItems::Type.order_by_name_asc.pluck(:base_type))
  end
end

RSpec.shared_examples 'filtering work item types by existing name' do
  context 'when filtering by an existing type name' do
    specify { expect(types_list).to contain_exactly(name.downcase) }
  end
end

RSpec.shared_examples 'filtering work item types by non-existing name' do
  context 'when filtering by an existing type name' do
    specify { expect(types_list).to be_empty }
  end
end
# rubocop:enabled Layout/LineLength
