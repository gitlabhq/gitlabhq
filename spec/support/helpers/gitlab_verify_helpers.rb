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
