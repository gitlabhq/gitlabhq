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

  it 'creates all default widget definitions' do
    WorkItems::WidgetDefinition.delete_all
    widget_mapping = ::Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter::WIDGETS_FOR_TYPE

    expect { subject }.to change { WorkItems::WidgetDefinition.count }
      .from(0).to(widget_mapping.values.flatten(1).count)

    created_widgets = WorkItems::WidgetDefinition.all.map do |widget|
      { name: widget.work_item_type.name, type: widget.widget_type, options: widget.widget_options }
    end
    expected_widgets = widget_mapping.flat_map do |type_sym, widget_types|
      widget_types.map do |type|
        type, type_options = type if type.is_a?(Array)

        { name: ::WorkItems::Type::TYPE_NAMES[type_sym], type: type.to_s, options: type_options }
      end
    end

    expect(created_widgets).to match_array(expected_widgets)
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

  it 'upserts default widget definitions if they already exist and type changes' do
    widget = WorkItems::WidgetDefinition.find_by_widget_type(:labels)

    widget.update!(widget_type: :assignees)

    expect do
      subject
      widget.reload
    end.to not_change(WorkItems::WidgetDefinition, :count).and(
      change { widget.widget_type }.from('assignees').to('labels')
    )
  end

  it 'does not change default widget definitions if they already exist with changed disabled status' do
    widget = WorkItems::WidgetDefinition.find_by_widget_type(:labels)

    widget.update!(disabled: true)

    expect do
      subject
      widget.reload
    end.to not_change(WorkItems::WidgetDefinition, :count).and(
      not_change { widget.disabled }
    )
  end

  it 'executes single INSERT query per types and widget definitions' do
    expect { subject }.to make_queries_matching(/INSERT/, 2)
  end

  context 'when some base types exist' do
    before do
      WorkItems::Type.limit(1).delete_all
    end

    it 'inserts all types and does nothing if some already existed' do
      expect { subject }.to make_queries_matching(/INSERT/, 2).and(
        change { WorkItems::Type.count }.by(1)
      )
      expect(WorkItems::Type.count).to eq(WorkItems::Type::BASE_TYPES.count)
    end
  end

  context 'when some widget definitions exist' do
    before do
      WorkItems::WidgetDefinition.limit(1).delete_all
    end

    it 'inserts all widget definitions and does nothing if some already existed' do
      expect { subject }.to make_queries_matching(/INSERT/, 2).and(
        change { WorkItems::WidgetDefinition.count }.by(1)
      )
    end
  end
end
