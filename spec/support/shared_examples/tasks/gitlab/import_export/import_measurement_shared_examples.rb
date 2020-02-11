# frozen_string_literal: true

RSpec.shared_examples 'import measurement' do
  context 'when measurement is enabled' do
    let(:measurement_enabled) { true }

    it 'prints measurement results' do
      expect { subject }.to output(including('Measuring enabled...', 'Number of sql calls:', 'Total GC count:', 'Total GC count:')).to_stdout
    end
  end

  context 'when measurement is not enabled' do
    let(:measurement_enabled) { false }

    it 'does not output measurement results' do
      expect { subject }.not_to output(/Measuring enabled.../).to_stdout
    end
  end

  context 'when measurement is not provided' do
    let(:task_params) { [username, namespace_path, project_name, archive_path] }

    it 'does not output measurement results' do
      expect { subject }.not_to output(/Measuring enabled.../).to_stdout
    end

    it 'does not raise any exception' do
      expect { subject }.not_to raise_error
    end
  end
end
