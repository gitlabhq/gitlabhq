# frozen_string_literal: true

RSpec.shared_examples 'provider status' do |factory|
  describe 'state_machine' do
    context 'when any => [:created]' do
      let(:provider) { build(factory, :creating) }

      it 'nullifies API credentials' do
        expect(provider).to receive(:nullify_credentials).and_call_original
        provider.make_created

        expect(provider).to be_created
      end
    end

    context 'when any => [:creating]' do
      let(:provider) { build(factory) }
      let(:operation_id) { 'operation-xxx' }

      it 'calls #assign_operation_id on the provider' do
        expect(provider).to receive(:assign_operation_id).with(operation_id).and_call_original

        provider.make_creating(operation_id)
      end
    end

    context 'when any => [:errored]' do
      let(:provider) { build(factory, :creating) }
      let(:status_reason) { 'err msg' }

      it 'calls #nullify_credentials on the provider' do
        expect(provider).to receive(:nullify_credentials).and_call_original

        provider.make_errored(status_reason)
      end

      it 'sets a status reason' do
        provider.make_errored(status_reason)

        expect(provider.status_reason).to eq('err msg')
      end

      context 'when status_reason is nil' do
        let(:provider) { build(factory, :errored) }

        it 'does not set status_reason' do
          provider.make_errored(nil)

          expect(provider.status_reason).not_to be_nil
        end
      end
    end
  end

  describe '#on_creation?' do
    using RSpec::Parameterized::TableSyntax

    subject { provider.on_creation? }

    where(:status, :result) do
      :scheduled | true
      :creating  | true
      :created   | false
      :errored   | false
    end

    with_them do
      let(:provider) { build(factory, status) }

      it { is_expected.to eq result }
    end
  end
end
