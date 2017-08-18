describe Gitlab::HealthChecks::PrometheusTextFormat do
  let(:metric_class) { Gitlab::HealthChecks::Metric }
  subject { described_class.new }

  describe '#marshal' do
    let(:sample_metrics) do
      [metric_class.new('metric1', 1),
       metric_class.new('metric2', 2)]
    end

    it 'marshal to text with non repeating type definition' do
      expected = <<-EXPECTED.strip_heredoc
        # TYPE metric1 gauge
        metric1 1
        # TYPE metric2 gauge
        metric2 2
      EXPECTED

      expect(subject.marshal(sample_metrics)).to eq(expected)
    end

    context 'metrics where name repeats' do
      let(:sample_metrics) do
        [metric_class.new('metric1', 1),
         metric_class.new('metric1', 2),
         metric_class.new('metric2', 3)]
      end

      it 'marshal to text with non repeating type definition' do
        expected = <<-EXPECTED.strip_heredoc
          # TYPE metric1 gauge
          metric1 1
          metric1 2
          # TYPE metric2 gauge
          metric2 3
        EXPECTED
        expect(subject.marshal(sample_metrics)).to eq(expected)
      end
    end
  end
end
