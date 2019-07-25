# frozen_string_literal: true

shared_examples 'helm commands' do
  describe '#generate_script' do
    let(:helm_setup) do
      <<~EOS
         set -xeo pipefail
      EOS
    end

    it 'returns appropriate command' do
      expect(subject.generate_script.strip).to eq((helm_setup + commands).strip)
    end
  end
end
