# frozen_string_literal: true

RSpec.shared_examples 'pipeline analytics graphql query' do |resource|
  describe 'clickhouse pipeline analytics' do
    let_it_be(:pipelines) do
      pipelines_data.map { |data| create_pipeline(**data) }
    end

    before do
      insert_ci_pipelines_to_click_house(pipelines)
    end

    it_behaves_like 'a working graphql query' do
      let(:fields) do
        <<~QUERY
          aggregate { #{period_fields} }
          timeSeries(period: DAY) { #{period_fields} }
        QUERY
      end

      before do
        perform_request
      end
    end

    def create_pipeline(status:, started_at:, duration:, ref:, source:)
      build_stubbed(:ci_pipeline, status, project: project.reload, ref: ref, source: source,
        created_at: 1.second.before(started_at), started_at: started_at, duration: duration)
    end

    describe 'aggregate', :aggregate_failures do
      subject(:aggregate) do
        perform_request

        graphql_data_at(resource, :pipelineAnalytics, :aggregate)
      end

      let(:fields) { query_graphql_field(:aggregate, {}, period_fields) }

      it "contains expected data for the last week" do
        perform_request

        expect_graphql_errors_to_be_empty
        expect(aggregate).to eq(
          'label' => nil,
          'all' => '0',
          'success' => '0',
          'failed' => '0',
          'other' => '0'
        )
      end

      context 'when there are pipelines in last week' do
        let(:simulated_current_time) { Time.utc(2024, 5, 11) }

        it "contains expected data for the last week" do
          perform_request

          expect_graphql_errors_to_be_empty
          expect(aggregate).to eq(
            'label' => nil,
            'all' => '5',
            'success' => '1',
            'failed' => '2',
            'other' => '1'
          )
        end

        context 'when requesting only full count' do
          let(:period_fields) { 'all: count' }

          it "contains expected data for the last week" do
            perform_request

            expect_graphql_errors_to_be_empty
            expect(aggregate).to eq('all' => '5')
          end
        end

        context 'when requesting only a specific status count' do
          let(:period_fields) { 'failed: count(status: FAILED)' }

          it "contains expected data for the last week" do
            perform_request

            expect_graphql_errors_to_be_empty
            expect(aggregate).to eq('failed' => '2')
          end
        end
      end

      context 'when time window is specified' do
        let(:from_time) { '2024-05-10T00:00:00+00:00' }
        let(:to_time) { '2024-05-11T00:00:00+00:00' }

        it "contains expected data for the period" do
          perform_request

          expect_graphql_errors_to_be_empty
          expect(aggregate).to eq(
            'label' => nil,
            'all' => '2',
            'success' => '1',
            'failed' => '0',
            'other' => '0'
          )
        end

        context 'when ref is specified' do
          let(:ref) { 'main2' }

          it "contains expected data for the period" do
            expect(aggregate).to eq(
              'label' => nil,
              'all' => '1',
              'success' => '1',
              'failed' => '0',
              'other' => '0'
            )
          end

          context 'when ref exists as a reserved ref' do
            let_it_be(:merge_request) do
              create(:merge_request, source_project: project, source_branch: 'my-mr-branch-ref',
                target_branch: 'main')
            end

            let(:ref) { merge_request.source_branch }

            it 'returns no pipelines' do
              expect(aggregate).to eq(
                'label' => nil,
                'all' => '0',
                'success' => '0',
                'failed' => '0',
                'other' => '0'
              )
            end

            context 'when pipeline on merge request with matching source branch exists' do
              let_it_be(:mr_pipelines) do
                [
                  create_pipeline(
                    status: :failed, started_at: 5.minutes.before(Time.utc(2024, 5, 11)),
                    duration: 2.minutes,
                    ref: "refs/#{Repository::REF_MERGE_REQUEST}/#{merge_request.iid}/head",
                    source: 'merge_request_event'),
                  create_pipeline(
                    status: :canceled, started_at: 5.minutes.before(Time.utc(2024, 5, 11)),
                    duration: 2.minutes,
                    ref: "refs/#{Repository::REF_MERGE_REQUEST}/#{merge_request.iid}/merge",
                    source: 'merge_request_event'),
                  create_pipeline(
                    status: :success, started_at: 5.minutes.before(Time.utc(2024, 5, 11)),
                    duration: 2.minutes,
                    ref: "refs/#{Repository::REF_MERGE_REQUEST}/#{merge_request.iid}/train",
                    source: 'merge_request_event')
                ]
              end

              before do
                insert_ci_pipelines_to_click_house(mr_pipelines)
              end

              it 'returns matched pipeline' do
                expect(aggregate).to eq(
                  'label' => nil,
                  'all' => '3',
                  'success' => '1',
                  'failed' => '1',
                  'other' => '1'
                )
              end

              context 'when FF is disabled' do
                before do
                  stub_feature_flags(include_reserved_refs_in_pipeline_refs_filter: false)
                end

                it 'returns no pipelines' do
                  expect(aggregate).to eq(
                    'label' => nil,
                    'all' => '0',
                    'success' => '0',
                    'failed' => '0',
                    'other' => '0'
                  )
                end
              end

              context 'when source does not include MERGE_REQUEST_EVENT' do
                let(:source) { :PUSH }

                it 'returns no pipelines' do
                  expect(aggregate).to eq(
                    'label' => nil,
                    'all' => '0',
                    'success' => '0',
                    'failed' => '0',
                    'other' => '0'
                  )
                end
              end
            end
          end
        end

        context 'when source is specified' do
          let(:source) { :PUSH }

          it "contains expected data for the period" do
            expect(aggregate).to eq(
              'label' => nil,
              'all' => '1',
              'success' => '1',
              'failed' => '0',
              'other' => '0'
            )
          end
        end

        context 'when source and ref are specified' do
          let(:source) { :PUSH }
          let(:ref) { 'main2' }

          it "contains expected data for the period" do
            expect(aggregate).to eq(
              'label' => nil,
              'all' => '1',
              'success' => '1',
              'failed' => '0',
              'other' => '0'
            )
          end

          context 'and source/ref are not a match' do
            let(:ref) { 'main' }

            it "contains expected data for the period" do
              expect(aggregate).to eq(
                'label' => nil,
                'all' => '0',
                'success' => '0',
                'failed' => '0',
                'other' => '0'
              )
            end
          end
        end
      end

      describe 'durationStatistics' do
        let(:period_fields) do
          <<~QUERY
            durationStatistics {
              p50
              p75
              p90
              p95
              p99
            }
          QUERY
        end

        subject(:perform_request) do
          post_graphql(query, current_user: user)

          graphql_data_at(resource, :pipelineAnalytics, :aggregate, :durationStatistics)
        end

        it_behaves_like 'a working graphql query' do
          before do
            perform_request
          end
        end

        context 'with no pipelines in time window' do
          let(:simulated_current_time) { Time.utc(2024, 1, 1) }
          let(:expected_duration_statistics) do
            {
              'p50' => 0,
              'p75' => 0,
              'p90' => 0,
              'p95' => 0,
              'p99' => 0
            }
          end

          it { is_expected.to eq(expected_duration_statistics) }
        end

        context 'with completed pipelines' do
          let(:simulated_current_time) { Time.utc(2024, 5, 11) }
          let(:expected_duration_statistics) do
            {
              'p50' => 1800.0,
              'p75' => 2700.0,
              'p90' => 5400.0,
              'p95' => 6300.0,
              'p99' => 7020.0
            }
          end

          it { is_expected.to eq(expected_duration_statistics) }
        end
      end
    end

    describe 'timeSeries', :aggregate_failures do
      subject(:time_series) do
        perform_request

        graphql_data_at(resource, :pipelineAnalytics, :timeSeries)
      end

      let(:time_series_args) { { period: :DAY } }
      let(:fields) { query_graphql_field(:timeSeries, time_series_args, period_fields) }

      describe 'durationStatistics' do
        let(:period_fields) do
          <<~QUERY
            label
            durationStatistics {
              p50
              p75
              p90
              p95
              p99
            }
          QUERY
        end

        subject(:perform_request) do
          post_graphql(query, current_user: user)

          graphql_data_at(resource, :pipelineAnalytics, :timeSeries, :durationStatistics)
        end

        it_behaves_like 'a working graphql query' do
          before do
            perform_request
          end
        end

        context 'with no pipelines in time window' do
          let(:simulated_current_time) { Time.utc(2024, 1, 1) }
          let(:expected_duration_statistics) do
            [
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 }
            ]
          end

          it { is_expected.to eq(expected_duration_statistics) }
        end

        context 'with completed pipelines' do
          let(:simulated_current_time) { Time.utc(2024, 5, 11) }
          let(:expected_duration_statistics) do
            [
              { "p50" => 2700.0, "p75" => 2700.0, "p90" => 2700.0, "p95" => 2700.0, "p99" => 2700.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 4500.0, "p75" => 5850.0, "p90" => 6660.0, "p95" => 6930.0, "p99" => 7146.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 0.0, "p75" => 0.0, "p90" => 0.0, "p95" => 0.0, "p99" => 0.0 },
              { "p50" => 1800.0, "p75" => 1800.0, "p90" => 1800.0, "p95" => 1800.0, "p99" => 1800.0 }
            ]
          end

          it { is_expected.to eq(expected_duration_statistics) }

          context 'when period is WEEK' do
            let(:time_series_args) { { period: :WEEK } }
            let(:expected_duration_statistics) do
              [
                { "p50" => 2700.0, "p75" => 2700.0, "p90" => 2700.0, "p95" => 2700.0, "p99" => 2700.0 },
                { "p50" => 1800.0, "p75" => 3150.0, "p90" => 5580.0, "p95" => 6390.0, "p99" => 7038.0 }
              ]
            end

            it { is_expected.to eq(expected_duration_statistics) }
          end
        end
      end
    end
  end
end
