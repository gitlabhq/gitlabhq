# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:product_intelligence:activate_metrics', :silence_stdout do
  def fake_metric(key_path, milestone: 'test_milestone', status: 'implemented')
    Gitlab::Usage::MetricDefinition.new(key_path, { key_path: key_path, milestone: milestone, status: status })
  end

  before do
    Rake.application.rake_require 'tasks/gitlab/product_intelligence'
    stub_warn_user_is_not_gitlab
  end

  describe 'activate_metrics' do
    it 'fails if the MILESTONE env var is not set' do
      stub_env('MILESTONE' => nil)

      expect { run_rake_task('gitlab:product_intelligence:activate_metrics') }.to raise_error(RuntimeError, 'Please supply the MILESTONE env var')
    end

    context 'with MILESTONE env var' do
      subject do
        updated_metrics = []

        file = double('file')
        allow(file).to receive(:<<) { |contents| updated_metrics << YAML.safe_load(contents) }
        allow(File).to receive(:open).and_yield(file)

        stub_env('MILESTONE' => 'test_milestone')
        run_rake_task('gitlab:product_intelligence:activate_metrics')

        updated_metrics
      end

      let(:metric_definitions) do
        {
          matching_metric: fake_metric('matching_metric'),
          matching_metric2: fake_metric('matching_metric2'),
          other_status_metric: fake_metric('other_status_metric', status: 'deprecated'),
          other_milestone_metric: fake_metric('other_milestone_metric', milestone: 'other_milestone')
        }
      end

      before do
        allow(Gitlab::Usage::MetricDefinition).to receive(:definitions).and_return(metric_definitions)
      end

      context 'with metric matching status and milestone' do
        it 'updates matching_metric yaml file' do
          expect(subject).to eq([
            { 'key_path' => 'matching_metric', 'milestone' => 'test_milestone', 'status' => 'data_available' },
            { 'key_path' => 'matching_metric2', 'milestone' => 'test_milestone', 'status' => 'data_available' }
          ])
        end
      end

      context 'without metrics definitions' do
        let(:metric_definitions) { {} }

        it 'runs successfully with no updates' do
          expect(subject).to eq([])
        end
      end

      context 'without matching metrics' do
        let(:metric_definitions) do
          {
            other_status_metric: fake_metric('other_status_metric', status: 'deprecated'),
            other_milestone_metric: fake_metric('other_milestone_metric', milestone: 'other_milestone')
          }
        end

        it 'runs successfully with no updates' do
          expect(subject).to eq([])
        end
      end
    end
  end
end
