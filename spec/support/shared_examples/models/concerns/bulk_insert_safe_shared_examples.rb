# frozen_string_literal: true

RSpec.shared_examples 'a BulkInsertSafe model' do |klass|
  # Call `.dup` on the class passed in, as a test in this set of examples
  # calls `belongs_to` on the class, thereby adding a new belongs_to
  # relationship to the model that can break remaining specs in the test suite.
  let(:target_class) { klass.dup }

  # We consider all callbacks unsafe for bulk insertions unless we have explicitly
  # allowed them (especially anything related to :save, :create, :commit, etc.)
  let(:unsafe_callbacks) do
    ActiveRecord::Callbacks::CALLBACKS.reject do |callback|
      cb_name = callback.to_s.gsub(/(before_|after_|around_)/, '').to_sym
      BulkInsertSafe::ALLOWED_CALLBACKS.include?(cb_name)
    end.to_set
  end

  context 'when calling class methods directly' do
    it 'raises an error when method is not bulk-insert safe' do
      unsafe_callbacks.each do |m|
        expect { target_class.send(m, nil) }.to(
          raise_error(BulkInsertSafe::MethodNotAllowedError),
          "Expected call to #{m} to raise an error, but it didn't"
        )
      end
    end

    it 'does not raise an error when method is bulk-insert safe' do
      BulkInsertSafe::ALLOWED_CALLBACKS.each do |name|
        expect { target_class.set_callback(name) {} }.not_to raise_error
      end
    end
  end

  describe '.bulk_insert!' do
    context 'when all items are valid' do
      it 'inserts them all' do
        items = valid_items_for_bulk_insertion

        expect(items).not_to be_empty
        expect { target_class.bulk_insert!(items) }.to change { target_class.count }.by(items.size)
      end

      it 'returns an empty array' do
        items = valid_items_for_bulk_insertion

        expect(items).not_to be_empty
        expect(target_class.bulk_insert!(items)).to eq([])
      end
    end

    context 'when some items are invalid' do
      it 'does not insert any of them and raises an error' do
        items = invalid_items_for_bulk_insertion

        # it is not always possible to create invalid items
        if items.any?
          expect { target_class.bulk_insert!(items) }.to raise_error(ActiveRecord::RecordInvalid)
          expect(target_class.count).to eq(0)
        end
      end

      it 'inserts them anyway when bypassing validations' do
        items = invalid_items_for_bulk_insertion

        # it is not always possible to create invalid items
        if items.any?
          expect(target_class.bulk_insert!(items, validate: false)).to eq([])
          expect(target_class.count).to eq(items.size)
        end
      end
    end
  end
end
