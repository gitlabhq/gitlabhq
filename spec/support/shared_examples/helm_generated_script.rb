shared_examples 'helm commands' do
  describe '#generate_script' do
    let(:helm_setup) do
      <<~EOS
         set -eo pipefail
      EOS
    end

    it 'should return appropriate command' do
      expect(subject.generate_script).to eq(helm_setup + commands)
    end
  end
end
