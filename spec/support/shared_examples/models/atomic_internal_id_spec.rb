require 'spec_helper'

shared_examples_for 'AtomicInternalId' do
  let(:allow_nil) { false }

  describe '.has_internal_id' do
    describe 'Module inclusion' do
      subject { described_class }

      it { is_expected.to include_module(AtomicInternalId) }
    end

    describe 'Validation' do
      before do
        allow_any_instance_of(described_class).to receive(:"ensure_#{scope}_#{internal_id_attribute}!") {}
      end

      it 'validates presence' do
        instance.valid?

        if allow_nil
          expect(instance.errors[internal_id_attribute]).to be_empty
        else
          expect(instance.errors[internal_id_attribute]).to include("can't be blank")
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
        expect(instance.public_send(internal_id_attribute)).to eq(iid)
      end

      it 'does not overwrite an existing internal id' do
        instance.public_send("#{internal_id_attribute}=", 4711)

        expect { subject }.not_to change { instance.public_send(internal_id_attribute) }
      end
    end
  end
end
