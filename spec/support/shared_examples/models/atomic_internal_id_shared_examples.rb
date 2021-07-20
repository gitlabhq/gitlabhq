# frozen_string_literal: true

RSpec.shared_examples 'AtomicInternalId' do |validate_presence: true|
  describe '.has_internal_id' do
    describe 'Module inclusion' do
      subject { described_class }

      it { is_expected.to include_module(AtomicInternalId) }
    end

    describe 'Validation' do
      context 'when presence validation is required' do
        before do
          skip unless validate_presence
        end

        context 'when creating an object' do
          before do
            allow_any_instance_of(described_class).to receive(:"ensure_#{scope}_#{internal_id_attribute}!")
          end

          it 'raises an error if the internal id is blank' do
            expect { instance.save! }.to raise_error(AtomicInternalId::MissingValueError)
          end
        end

        context 'when updating an object' do
          it 'raises an error if the internal id is blank' do
            instance.save!

            write_internal_id(nil)
            allow(instance).to receive(:"ensure_#{scope}_#{internal_id_attribute}!")

            expect { instance.save! }.to raise_error(AtomicInternalId::MissingValueError)
          end
        end
      end

      context 'when presence validation is not required' do
        before do
          skip if validate_presence
        end

        context 'when creating an object' do
          before do
            allow_any_instance_of(described_class).to receive(:"ensure_#{scope}_#{internal_id_attribute}!")
          end

          it 'does not raise an error if the internal id is blank' do
            expect(read_internal_id).to be_nil

            expect { instance.save! }.not_to raise_error
          end
        end

        context 'when updating an object' do
          it 'does not raise an error if the internal id is blank' do
            instance.save!

            write_internal_id(nil)
            allow(instance).to receive(:"ensure_#{scope}_#{internal_id_attribute}!")

            expect { instance.save! }.not_to raise_error
          end
        end
      end
    end

    describe 'Creating an instance' do
      subject { instance.save! }

      it 'saves a new instance properly' do
        expect { subject }.not_to raise_error
      end
    end

    describe 'internal id generation' do
      subject { instance.save! }

      it 'calls InternalId.generate_next and sets internal id attribute' do
        iid = rand(1..1000)

        expect(InternalId).to receive(:generate_next).with(instance, scope_attrs, usage, any_args).and_return(iid)
        subject
        expect(read_internal_id).to eq(iid)
      end

      it 'does not overwrite an existing internal id' do
        write_internal_id(4711)

        expect { subject }.not_to change { read_internal_id }
      end

      context 'when the instance has an internal ID set' do
        let(:internal_id) { 9001 }

        it 'calls InternalId.update_last_value and sets the `last_value` to that of the instance' do
          write_internal_id(internal_id)

          expect(InternalId)
            .to receive(:track_greatest)
            .with(instance, scope_attrs, usage, internal_id, any_args)
            .and_return(internal_id)
          subject
        end
      end
    end

    describe 'unsetting the instance internal id on rollback' do
      context 'when the internal id has been changed' do
        context 'when the internal id is automatically set' do
          it 'clears it on the instance' do
            expect_iid_to_be_set_and_rollback

            expect(read_internal_id).to be_nil
          end
        end

        context 'when the internal id is manually set' do
          it 'does not clear it on the instance' do
            write_internal_id(100)

            expect_iid_to_be_set_and_rollback

            expect(read_internal_id).not_to be_nil
          end
        end
      end

      context 'when the internal id has not been changed' do
        it 'preserves the value on the instance' do
          instance.save!
          original_id = read_internal_id

          expect(original_id).not_to be_nil

          expect_iid_to_be_set_and_rollback

          expect(read_internal_id).to eq(original_id)
        end
      end

      def expect_iid_to_be_set_and_rollback
        ActiveRecord::Base.transaction(requires_new: true) do
          instance.save!

          expect(read_internal_id).not_to be_nil

          raise ActiveRecord::Rollback
        end
      end
    end

    describe 'supply of internal ids' do
      let(:scope_value) { scope_attrs.each_value.first }
      let(:method_name) { :"with_#{scope}_#{internal_id_attribute}_supply" }

      it 'provides a persistent supply of IID values, sensitive to the current state' do
        iid = rand(1..1000)
        write_internal_id(iid)
        instance.public_send(:"track_#{scope}_#{internal_id_attribute}!")

        # Allocate 3 IID values
        described_class.public_send(method_name, scope_value) do |supply|
          3.times { supply.next_value }
        end

        described_class.public_send(method_name, scope_value) do |supply|
          expect(supply.next_value).to eq(iid + 4)
        end
      end
    end

    describe "#reset_scope_internal_id_attribute" do
      it 'rewinds the allocated IID' do
        expect { ensure_scope_attribute! }.not_to raise_error
        expect(read_internal_id).not_to be_nil

        expect(reset_scope_attribute).to be_nil
        expect(read_internal_id).to be_nil
      end

      it 'allocates the same IID' do
        internal_id = ensure_scope_attribute!
        reset_scope_attribute
        expect(read_internal_id).to be_nil

        expect(ensure_scope_attribute!).to eq(internal_id)
      end
    end

    def ensure_scope_attribute!
      instance.public_send(:"ensure_#{scope}_#{internal_id_attribute}!")
    end

    def reset_scope_attribute
      instance.public_send(:"reset_#{scope}_#{internal_id_attribute}")
    end

    def read_internal_id
      instance.public_send(internal_id_attribute)
    end

    def write_internal_id(value)
      instance.public_send(:"#{internal_id_attribute}=", value)
    end
  end
end
