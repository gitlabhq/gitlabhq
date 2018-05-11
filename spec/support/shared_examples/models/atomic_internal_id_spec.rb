require 'spec_helper'

shared_examples_for 'AtomicInternalId' do
  let(:validate_presence) { true }

  describe '.has_internal_id' do
    describe 'Module inclusion' do
      subject { described_class }

      it { is_expected.to include_module(AtomicInternalId) }
    end

    describe 'Validation' do
      before do
        allow_any_instance_of(described_class).to receive(:"ensure_#{scope_attrs.keys.first}_#{internal_id_attribute}!") {}
      end

      it 'validates presence' do
        instance.valid?

        expect(instance.errors[:iid]).to include("can't be blank") if validate_presence
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
