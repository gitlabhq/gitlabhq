# frozen_string_literal: true

RSpec.shared_examples 'migration that adds widget to work items definitions' do |widget_name:|
  let(:migration) { described_class.new }
  let(:work_item_definitions) { table(:work_item_widget_definitions) }

  describe '#up' do
    it "creates widget definition in all types" do
      work_item_definitions.where(name: widget_name).delete_all

      expect { migrate! }.to change { work_item_definitions.count }.by(7)
      expect(work_item_definitions.all.pluck(:name)).to include(widget_name)
    end

    it 'logs a warning if the type is missing' do
      allow(described_class::WorkItemType).to receive(:find_by_name_and_namespace_id).and_call_original
      allow(described_class::WorkItemType).to receive(:find_by_name_and_namespace_id)
        .with('Issue', nil).and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn).with('type Issue is missing, not adding widget')
      migrate!
    end
  end

  describe '#down' do
    it "removes definitions for widget" do
      migrate!

      expect { migration.down }.to change { work_item_definitions.count }.by(-7)
      expect(work_item_definitions.all.pluck(:name)).not_to include(widget_name)
    end
  end
end
