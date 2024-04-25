# frozen_string_literal: true

RSpec.shared_examples '#set_is_ambiguous_ref when ref is ambiguous' do
  context 'when the ref_type is nil' do
    let(:ref_type) { nil }

    it '@ambiguous_ref return true' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(true)
    end
  end

  context 'when the ref_type is empty' do
    let(:ref_type) { '' }

    it '@ambiguous_ref return true' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(true)
    end
  end

  context 'when the ref_type is present' do
    let(:ref_type) { 'heads' }

    it '@ambiguous_ref return false' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(false)
    end
  end
end

RSpec.shared_examples '#set_is_ambiguous_ref when ref is not ambiguous' do
  context 'when the ref_type is nil' do
    let(:ref_type) { nil }

    it '@ambiguous_ref return false' do
      expect(controller.instance_variable_get(:@is_ambiguous_ref)).to eq(false)
    end
  end
end
