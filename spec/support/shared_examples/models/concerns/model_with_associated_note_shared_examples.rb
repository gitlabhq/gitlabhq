# frozen_string_literal: true

# Requires these let variables to be set by the caller:
# - note
# - record_attrs
RSpec.shared_examples 'model with associated note' do
  describe 'validations' do
    context "when `skip_namespace_validation?` is `false`" do
      before do
        allow_next_instance_of(described_class) do |record|
          allow(record).to receive(:skip_namespace_validation?).and_return(false)
        end
      end

      it { is_expected.to validate_presence_of(:namespace_id).on(:create) }
    end

    context "when `skip_namespace_validation?` is `true`" do
      before do
        allow_next_instance_of(described_class) do |record|
          allow(record).to receive(:skip_namespace_validation?).and_return(true)
        end
      end

      it { is_expected.not_to validate_presence_of(:namespace_id).on(:create) }
    end
  end

  describe 'callbacks' do
    describe '#ensure_namespace_id' do
      let(:new_record) { described_class.new(record_attrs) }

      context "when `skip_namespace_validation?` is `false`" do
        before do
          allow(new_record).to receive(:skip_namespace_validation?).and_return(false)
        end

        it 'sets the namespace id from the note namespace id' do
          expect(new_record).to receive(:ensure_namespace_id).and_call_original
          new_record.save!

          expect(new_record.reload.namespace_id).not_to be_nil
          expect(new_record.namespace_id).to eq(note.namespace_id)
        end
      end

      context "when `skip_namespace_validation?` is `true`" do
        before do
          allow(new_record).to receive(:skip_namespace_validation?).and_return(true)
        end

        it 'does not execute callback' do
          expect(new_record).not_to receive(:ensure_namespace_id)

          new_record.save!
        end
      end
    end
  end
end
