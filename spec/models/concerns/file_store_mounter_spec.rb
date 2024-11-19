# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FileStoreMounter, :aggregate_failures, feature_category: :shared do
  let(:uploader_class) do
    Class.new do
      def object_store
        :object_store
      end
    end
  end

  let(:test_class) { Class.new { include(FileStoreMounter) } }

  let(:uploader_instance) { uploader_class.new }

  describe '.mount_file_store_uploader' do
    using RSpec::Parameterized::TableSyntax

    subject(:mount_file_store_uploader) do
      test_class.mount_file_store_uploader uploader_class, skip_store_file: skip_store_file, file_field: file_field
    end

    where(:skip_store_file, :file_field) do
      true   | :file
      false  | :file
      false  | :signed_file
      true   | :signed_file
    end

    with_them do
      it 'defines instance methods and registers a callback' do
        expect(test_class).to receive(:mount_uploader).with(file_field, uploader_class)
        expect(test_class).to receive(:define_method).with("update_#{file_field}_store")
        expect(test_class).to receive(:define_method).with("store_#{file_field}_now!")

        if skip_store_file
          expect(test_class).to receive(:skip_callback).with(:save, :after, "store_#{file_field}!".to_sym)
          expect(test_class).not_to receive(:after_save)
        else
          expect(test_class).not_to receive(:skip_callback)
          expect(test_class)
            .to receive(:after_save)
                  .with("update_#{file_field}_store".to_sym, if: "saved_change_to_#{file_field}?".to_sym)
        end

        mount_file_store_uploader
      end
    end

    context 'with an unknown file_field' do
      let(:skip_store_file) { false }
      let(:file_field) { 'unknown' }

      it do
        expect { mount_file_store_uploader }.to raise_error(ArgumentError, 'file_field not allowed: unknown')
      end
    end
  end

  context 'with an instance' do
    let(:instance) { test_class.new }

    before do
      allow(test_class).to receive(:mount_uploader)
      allow(test_class).to receive(:after_save)
      test_class.mount_file_store_uploader uploader_class
    end

    describe '#update_file_store' do
      subject(:update_file_store) { instance.update_file_store }

      it 'calls update column' do
        expect(instance).to receive(:file).and_return(uploader_instance)
        expect(instance).to receive(:[]).with('file_store').and_return(nil)
        expect(instance).to receive(:update_column).with('file_store', :object_store)

        update_file_store
      end

      context 'when the model file store is set to the same value' do
        it 'does not call update column' do
          expect(instance).to receive(:file).and_return(uploader_instance)
          expect(instance).to receive(:[]).with('file_store').and_return(:object_store)
          expect(instance).not_to receive(:update_column)

          update_file_store
        end
      end
    end

    describe '#store_file_now!' do
      subject(:store_file_now!) { instance.store_file_now! }

      it 'calls the dynamic functions' do
        expect(instance).to receive(:store_file!)
        expect(instance).to receive(:update_file_store)

        store_file_now!
      end
    end
  end
end
