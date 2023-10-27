# frozen_string_literal: true

RSpec.shared_examples '#set_is_ambiguous_ref when ref is ambiguous' do
  context 'when the ref_type is nil' do
    let(:ref_type) { nil }

    it '@ambiguous_ref return false when ff is disabled' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(false)
    end

    context 'when the ambiguous_ref_modal ff is enabled' do
      let(:ambiguous_ref_modal) { true }

      it '@ambiguous_ref return true' do
        expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(true)
      end
    end
  end

  context 'when the ref_type is empty' do
    let(:ref_type) { '' }

    it '@ambiguous_ref return false when ff is disabled' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(false)
    end

    context 'when the ambiguous_ref_modal ff is enabled' do
      let(:ambiguous_ref_modal) { true }

      it '@ambiguous_ref return true' do
        expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(true)
      end
    end
  end

  context 'when the ref_type is present' do
    let(:ref_type) { 'heads' }
    let(:ambiguous_ref_modal) { true }

    it '@ambiguous_ref return false' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(false)
    end
  end
end

RSpec.shared_examples '#set_is_ambiguous_ref when ref is not ambiguous' do
  context 'when the ref_type is nil' do
    let(:ref_type) { nil }
    let(:ambiguous_ref_modal) { true }

    it '@ambiguous_ref return false' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(false)
    end
  end
end
