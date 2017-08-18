require 'spec_helper'

describe Gitlab::Prometheus::AdditionalMetricsParser do
  include Prometheus::MetricBuilders

  let(:parser_error_class) { Gitlab::Prometheus::ParsingError }

  describe '#load_groups_from_yaml' do
    subject { described_class.load_groups_from_yaml }

    describe 'parsing sample yaml' do
      let(:sample_yaml) do
        <<-EOF.strip_heredoc
          - group: group_a
            priority: 1
            metrics:
              - title: "title"
                required_metrics: [ metric_a, metric_b ]
                weight: 1
                queries: [{ query_range: 'query_range_a', label: label, unit: unit }]
              - title: "title"
                required_metrics: [metric_a]
                weight: 1
                queries: [{ query_range: 'query_range_empty' }]
          - group: group_b
            priority: 1
            metrics:
              - title: title
                required_metrics: ['metric_a']
                weight: 1
                queries: [{query_range: query_range_a}]
        EOF
      end

      before do
        allow(described_class).to receive(:load_yaml_file) { YAML.load(sample_yaml) }
      end

      it 'parses to two metric groups with 2 and 1 metric respectively' do
        expect(subject.count).to eq(2)
        expect(subject[0].metrics.count).to eq(2)
        expect(subject[1].metrics.count).to eq(1)
      end

      it 'provide group data' do
        expect(subject[0]).to have_attributes(name: 'group_a', priority: 1)
        expect(subject[1]).to have_attributes(name: 'group_b', priority: 1)
      end

      it 'provides metrics data' do
        metrics = subject.flat_map(&:metrics)

        expect(metrics.count).to eq(3)
        expect(metrics[0]).to have_attributes(title: 'title', required_metrics: %w(metric_a metric_b), weight: 1)
        expect(metrics[1]).to have_attributes(title: 'title', required_metrics: %w(metric_a), weight: 1)
        expect(metrics[2]).to have_attributes(title: 'title', required_metrics: %w{metric_a}, weight: 1)
      end

      it 'provides query data' do
        queries = subject.flat_map(&:metrics).flat_map(&:queries)

        expect(queries.count).to eq(3)
        expect(queries[0]).to eq(query_range: 'query_range_a', label: 'label', unit: 'unit')
        expect(queries[1]).to eq(query_range: 'query_range_empty')
        expect(queries[2]).to eq(query_range: 'query_range_a')
      end
    end

    shared_examples 'required field' do |field_name|
      context "when #{field_name} is nil" do
        before do
          allow(described_class).to receive(:load_yaml_file) { YAML.load(field_missing) }
        end

        it 'throws parsing error' do
          expect { subject }.to raise_error(parser_error_class, /#{field_name} can't be blank/i)
        end
      end

      context "when #{field_name} are not specified" do
        before do
          allow(described_class).to receive(:load_yaml_file) { YAML.load(field_nil) }
        end

        it 'throws parsing error' do
          expect { subject }.to raise_error(parser_error_class, /#{field_name} can't be blank/i)
        end
      end
    end

    describe 'group required fields' do
      it_behaves_like 'required field', 'metrics' do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
          EOF
        end
      end

      it_behaves_like 'required field', 'name' do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group:
              priority: 1
              metrics: []
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - priority: 1
              metrics: []
          EOF
        end
      end

      it_behaves_like 'required field', 'priority' do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority:
              metrics: []
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - group: group_a
              metrics: []
          EOF
        end
      end
    end

    describe 'metrics fields parsing' do
      it_behaves_like 'required field', 'title' do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title:
                required_metrics: []
                weight: 1
                queries: []
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - required_metrics: []
                weight: 1
                queries: []
          EOF
        end
      end

      it_behaves_like 'required field', 'required metrics' do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title: title
                required_metrics:
                weight: 1
                queries: []
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title: title
                weight: 1
                queries: []
          EOF
        end
      end

      it_behaves_like 'required field', 'weight' do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title: title
                required_metrics: []
                weight:
                queries: []
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title: title
                required_metrics: []
                queries: []
          EOF
        end
      end

      it_behaves_like 'required field', :queries do
        let(:field_nil) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title: title
                required_metrics: []
                weight: 1
                queries:
          EOF
        end

        let(:field_missing) do
          <<-EOF.strip_heredoc
            - group: group_a
              priority: 1
              metrics:
              - title: title
                required_metrics: []
                weight: 1
          EOF
        end
      end
    end
  end
end
