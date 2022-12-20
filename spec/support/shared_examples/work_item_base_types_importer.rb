# frozen_string_literal: true

RSpec.shared_examples 'work item base types importer' do
  it "creates all base work item types if they don't exist" do
    WorkItems::Type.delete_all

    expect { subject }.to change { WorkItems::Type.count }.from(0).to(WorkItems::Type::BASE_TYPES.count)

    types_in_db = WorkItems::Type.all.map { |type| type.slice(:base_type, :icon_name, :name).symbolize_keys }
    expected_types = WorkItems::Type::BASE_TYPES.map do |type, attributes|
      attributes.slice(:icon_name, :name).merge(base_type: type.to_s)
    end

    expect(types_in_db).to match_array(expected_types)
    expect(WorkItems::Type.all).to all(be_valid)
  end

  it 'upserts base work item types if they already exist' do
    first_type = WorkItems::Type.first
    original_name = first_type.name

    first_type.update!(name: original_name.upcase)

    expect do
      subject
      first_type.reload
    end.to not_change(WorkItems::Type, :count).and(
      change { first_type.name }.from(original_name.upcase).to(original_name)
    )
  end

  it 'executes a single INSERT query' do
    expect { subject }.to make_queries_matching(/INSERT/, 1)
  end

  context 'when some base types exist' do
    before do
      WorkItems::Type.limit(1).delete_all
    end

    it 'inserts all types and does nothing if some already existed' do
      expect { subject }.to make_queries_matching(/INSERT/, 1).and(
        change { WorkItems::Type.count }.by(1)
      )
      expect(WorkItems::Type.count).to eq(WorkItems::Type::BASE_TYPES.count)
    end
  end
end
