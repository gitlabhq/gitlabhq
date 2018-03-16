require 'spec_helper'

shared_examples_for 'AtomicInternalId' do
  describe '.has_internal_id' do
    describe 'Module inclusion' do
      subject { described_class }

      it { is_expected.to include_module(AtomicInternalId) }
    end

    describe 'Validation' do
      subject { instance }

      before do
        allow(InternalId).to receive(:generate_next).and_return(nil)
      end

      it { is_expected.to validate_presence_of(internal_id_attribute) }
      it { is_expected.to validate_numericality_of(internal_id_attribute) }
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
