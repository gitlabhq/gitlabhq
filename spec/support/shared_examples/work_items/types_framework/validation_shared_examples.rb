# frozen_string_literal: true

RSpec.shared_examples 'validates work item type ID' do
  describe '#validate_work_item_type_id' do
    context 'with valid work item type ID' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'with invalid work item type ID' do
      it 'is invalid' do
        subject.work_item_type_id = 999
        subject.validate
        expect(subject.errors[:work_item_type])
          .to include('must use a valid work item type ID')
      end
    end
  end
end
