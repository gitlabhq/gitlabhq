RSpec.shared_examples 'additional metrics query' do
  include Prometheus::MetricBuilders

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  let(:metric_names) { %w{metric_a metric_b} }

  let(:query_range_result) do
    [{ 'metric': {}, 'values': [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']] }]
  end

  let(:client) { double('prometheus_client') }
  let(:query_result) { described_class.new(client).query(*query_params) }
  let(:project) { create(:project) }
  let(:environment) { create(:environment, slug: 'environment-slug', project: project) }

  before do
    allow(client).to receive(:label_values).and_return(metric_names)
    allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group(metrics: [simple_metric])])
  end

  context 'metrics query context' do
    subject! { described_class.new(client) }

    shared_examples 'query context containing environment slug and filter' do
      it 'contains ci_environment_slug' do
        expect(subject).to receive(:query_metrics).with(project, hash_including(ci_environment_slug: environment.slug))

        subject.query(*query_params)
      end

      it 'contains environment filter' do
        expect(subject).to receive(:query_metrics).with(
          project,
          hash_including(
            environment_filter: "container_name!=\"POD\",environment=\"#{environment.slug}\""
          )
        )

        subject.query(*query_params)
      end
    end

    describe 'project has Kubernetes service' do
      shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
        let(:environment) { create(:environment, slug: 'environment-slug', project: project) }
        let(:kube_namespace) { project.deployment_platform.actual_namespace }

        it_behaves_like 'query context containing environment slug and filter'

        it 'query context contains kube_namespace' do
          expect(subject).to receive(:query_metrics).with(project, hash_including(kube_namespace: kube_namespace))

          subject.query(*query_params)
        end
      end

      context 'when user configured kubernetes from Integration > Kubernetes' do
        let(:project) { create(:kubernetes_project) }

        it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
      end

      context 'when user configured kubernetes from CI/CD > Clusters' do
        let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
        let(:project) { cluster.project }

        it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
      end
    end

    describe 'project without Kubernetes service' do
      it_behaves_like 'query context containing environment slug and filter'

      it 'query context contains empty kube_namespace' do
        expect(subject).to receive(:query_metrics).with(project, hash_including(kube_namespace: ''))

        subject.query(*query_params)
      end
    end
  end

  context 'with one group where two metrics is found' do
    before do
      allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group])
    end

    context 'some queries return results' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_empty', any_args).and_return([])
      end

      it 'return group data only for queries with results' do
        expected = [
          {
            group: 'name',
            priority: 1,
            metrics: [
              {
                title: 'title', weight: 1, y_label: 'Values', queries: [
                { query_range: 'query_range_a', result: query_range_result },
                { query_range: 'query_range_b', label: 'label', unit: 'unit', result: query_range_result }
              ]
              }
            ]
          }
        ]

        expect(query_result).to match_schema('prometheus/additional_metrics_query_result')
        expect(query_result).to eq(expected)
      end
    end
  end

  context 'with custom metrics' do
    let!(:metric) { create(:prometheus_metric, project: project) }
    before do
      allow(client).to receive(:query_range).with('avg(metric)', any_args).and_return(query_range_result)
    end

    context 'without common metrics' do
      before do
        allow(metric_group_class).to receive(:common_metrics).and_return([])
      end

      it 'return group data for custom metric' do
        queries_with_result = { queries: [{ query_range: 'avg(metric)', unit: 'm/s', label: 'legend', result: query_range_result }] }
        expect(query_result).to match_schema('prometheus/additional_metrics_query_result')

        expect(query_result.count).to eq(1)
        expect(query_result.first[:metrics].count).to eq(1)

        expect(query_result.first[:metrics].first).to include(queries_with_result)
      end
    end

    context 'with common metrics' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)

        allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group(metrics: [simple_metric])])
      end

      it 'return group data for custom metric' do
        custom_queries_with_result = { queries: [{ query_range: 'avg(metric)', unit: 'm/s', label: 'legend', result: query_range_result }] }
        common_queries_with_result = { queries: [{ query_range: 'query_range_a', result: query_range_result }] }

        expect(query_result).to match_schema('prometheus/additional_metrics_query_result')

        expect(query_result.count).to eq(2)
        expect(query_result).to all(satisfy { |r| r[:metrics].count == 1 })

        expect(query_result[0][:metrics].first).to include(common_queries_with_result)
        expect(query_result[1][:metrics].first).to include(custom_queries_with_result)
      end
    end
  end

  context 'with two groups with one metric each' do
    let(:metrics) { [simple_metric(queries: [simple_query])] }

    before do
      allow(metric_group_class).to receive(:common_metrics).and_return(
        [
          simple_metric_group(name: 'group_a', metrics: [simple_metric(queries: [simple_query])]),
          simple_metric_group(name: 'group_b', metrics: [simple_metric(title: 'title_b', queries: [simple_query('b')])])
        ])
      allow(client).to receive(:label_values).and_return(metric_names)
    end

    context 'both queries return results' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
      end

      it 'return group data both queries' do
        queries_with_result_a = { queries: [{ query_range: 'query_range_a', result: query_range_result }] }
        queries_with_result_b = { queries: [{ query_range: 'query_range_b', result: query_range_result }] }

        expect(query_result).to match_schema('prometheus/additional_metrics_query_result')

        expect(query_result.count).to eq(2)
        expect(query_result).to all(satisfy { |r| r[:metrics].count == 1 })

        expect(query_result[0][:metrics].first).to include(queries_with_result_a)
        expect(query_result[1][:metrics].first).to include(queries_with_result_b)
      end
    end

    context 'one query returns result' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return([])
      end

      it 'return group data only for query with results' do
        queries_with_result = { queries: [{ query_range: 'query_range_a', result: query_range_result }] }

        expect(query_result).to match_schema('prometheus/additional_metrics_query_result')

        expect(query_result.count).to eq(1)
        expect(query_result).to all(satisfy { |r| r[:metrics].count == 1 })

        expect(query_result.first[:metrics].first).to include(queries_with_result)
      end
    end
  end
end
