# frozen_string_literal: true

RSpec.shared_examples 'a BulkInsertSafe model' do |klass|
  # Call `.dup` on the class passed in, as a test in this set of examples
  # calls `belongs_to` on the class, thereby adding a new belongs_to
  # relationship to the model that can break remaining specs in the test suite.
  let(:target_class) { klass.dup }

  # We consider all callbacks unsafe for bulk insertions unless we have explicitly
  # whitelisted them (esp. anything related to :save, :create, :commit etc.)
  let(:callback_method_blacklist) do
    ActiveRecord::Callbacks::CALLBACKS.reject do |callback|
      cb_name = callback.to_s.gsub(/(before_|after_|around_)/, '').to_sym
      BulkInsertSafe::CALLBACK_NAME_WHITELIST.include?(cb_name)
    end.to_set
  end

  context 'when calling class methods directly' do
    it 'raises an error when method is not bulk-insert safe' do
      callback_method_blacklist.each do |m|
        expect { target_class.send(m, nil) }.to(
          raise_error(BulkInsertSafe::MethodNotAllowedError),
          "Expected call to #{m} to raise an error, but it didn't"
        )
      end
    end

    it 'does not raise an error when method is bulk-insert safe' do
      BulkInsertSafe::CALLBACK_NAME_WHITELIST.each do |name|
        expect { target_class.set_callback(name) {} }.not_to raise_error
      end
    end

    it 'does not raise an error when the call is triggered by belongs_to' do
      expect { target_class.belongs_to(:other_record) }.not_to raise_error
    end
  end
end
