RSpec.shared_examples 'Gitlab::Verify::BatchVerifier subclass' do
  describe 'batching' do
    let(:first_batch) { objects[0].id..objects[0].id }
    let(:second_batch) { objects[1].id..objects[1].id }
    let(:third_batch) { objects[2].id..objects[2].id }

    it 'iterates through objects in batches' do
      expect(collect_ranges).to eq([first_batch, second_batch, third_batch])
    end

    it 'allows the starting ID to be specified' do
      expect(collect_ranges(start: second_batch.first)).to eq([second_batch, third_batch])
    end

    it 'allows the finishing ID to be specified' do
      expect(collect_ranges(finish: second_batch.last)).to eq([first_batch, second_batch])
    end
  end
end

module GitlabVerifyHelpers
  def collect_ranges(args = {})
    verifier = described_class.new(args.merge(batch_size: 1))

    collect_results(verifier).map { |range, _| range }
  end

  def collect_failures
    verifier = described_class.new(batch_size: 1)

    out = {}

    collect_results(verifier).map { |_, failures| out.merge!(failures) }

    out
  end

  def collect_results(verifier)
    out = []

    verifier.run_batches { |*args| out << args }

    out
  end
end
