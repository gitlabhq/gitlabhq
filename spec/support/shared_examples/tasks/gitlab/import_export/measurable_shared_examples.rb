# frozen_string_literal: true

RSpec.shared_examples 'measurable' do
  context 'when measurement is enabled' do
    let(:measurement_enabled) { true }

    it 'prints measurement results' do
      expect { subject }.to output(including('time_to_finish')).to_stdout
    end
  end

  context 'when measurement is not enabled' do
    let(:measurement_enabled) { false }

    it 'does not output measurement results' do
      expect { subject }.not_to output(/time_to_finish/).to_stdout
    end
  end

  context 'when measurement is not provided' do
    let(:measurement_enabled) { nil }

    it 'does not output measurement results' do
      expect { subject }.not_to output(/time_to_finish/).to_stdout
    end

    it 'does not raise any exception' do
      expect { subject }.not_to raise_error
    end
  end
end
