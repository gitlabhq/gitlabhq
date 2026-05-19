# frozen_string_literal: true

RSpec.shared_examples 'validates work item type ID' do
  describe '#validate_work_item_type_id' do
    context 'when work_item_type_id is not changing' do
      it 'skips validation even with an unrecognized type ID' do
        allow(subject).to receive(:will_save_change_to_work_item_type_id?).and_return(false)
        subject.work_item_type_id = 999_999
        subject.validate
        expect(subject.errors[:work_item_type]).not_to include('is not a recognized work item type')
      end
    end

    context 'when work_item_type_id is changing' do
      context 'with a recognized type' do
        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context 'with an unrecognized type ID' do
        it 'is invalid with the correct error' do
          subject.work_item_type_id = 999_999
          subject.validate
          expect(subject.errors[:work_item_type])
            .to include('is not a recognized work item type')
        end
      end
    end
  end
end
