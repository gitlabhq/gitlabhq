# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Alerting::Alert do
  let_it_be(:project) { create(:project) }

  let(:alert) { build(:alerting_alert, project: project, payload: payload) }
  let(:payload) { {} }

  shared_context 'gitlab alert' do
    let!(:gitlab_alert) { create(:prometheus_alert, project: project) }
    let(:gitlab_alert_id) { gitlab_alert.id }

    before do
      payload['labels'] = {
        'gitlab_alert_id' => gitlab_alert.prometheus_metric_id.to_s,
        'gitlab_prometheus_alert_id' => gitlab_alert_id
      }
    end
  end

  shared_context 'full query' do
    before do
      payload['generatorURL'] = 'http://localhost:9090/graph?g0.expr=vector%281%29'
    end
  end

  shared_examples 'invalid alert' do
    it 'is invalid' do
      expect(alert).not_to be_valid
    end
  end

  shared_examples 'parse payload' do |*pairs|
    context 'without payload' do
      it { is_expected.to be_nil }
    end

    pairs.each do |pair|
      context "with #{pair}" do
        let(:value) { 'some value' }

        before do
          section, name = pair.split('/')
          payload[section] = { name => value }
        end

        it { is_expected.to eq(value) }
      end
    end
  end

  describe '#gitlab_alert' do
    subject { alert.gitlab_alert }

    context 'without payload' do
      it { is_expected.to be_nil }
    end

    context 'with gitlab alert' do
      include_context 'gitlab alert'

      it { is_expected.to eq(gitlab_alert) }
    end

    context 'with unknown gitlab alert' do
      include_context 'gitlab alert' do
        let(:gitlab_alert_id) { 'unknown' }
      end

      it { is_expected.to be_nil }
    end

    context 'when two alerts with the same metric exist' do
      include_context 'gitlab alert'

      let!(:second_gitlab_alert) do
        create(:prometheus_alert,
          project: project,
          prometheus_metric_id: gitlab_alert.prometheus_metric_id
        )
      end

      context 'alert id given in params' do
        before do
          payload['labels'] = {
            'gitlab_alert_id' => gitlab_alert.prometheus_metric_id.to_s,
            'gitlab_prometheus_alert_id' => second_gitlab_alert.id
          }
        end

        it { is_expected.to eq(second_gitlab_alert) }
      end

      context 'metric id given in params' do
        # This tests the case when two alerts are found, as metric id
        # is not unique.

        # Note the metric id was incorrectly named as 'gitlab_alert_id'
        # in PrometheusAlert#to_param.
        before do
          payload['labels'] = { 'gitlab_alert_id' => gitlab_alert.prometheus_metric_id }
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#title' do
    subject { alert.title }

    it_behaves_like 'parse payload',
      'annotations/title',
      'annotations/summary',
      'labels/alertname'

    context 'with gitlab alert' do
      include_context 'gitlab alert'

      context 'with annotations/title' do
        let(:value) { 'annotation title' }

        before do
          payload['annotations'] = { 'title' => value }
        end

        it { is_expected.to eq(gitlab_alert.title) }
      end
    end
  end

  describe '#description' do
    subject { alert.description }

    it_behaves_like 'parse payload', 'annotations/description'
  end

  describe '#annotations' do
    subject { alert.annotations }

    context 'without payload' do
      it { is_expected.to eq([]) }
    end

    context 'with payload' do
      before do
        payload['annotations'] = { 'foo' => 'value1', 'bar' => 'value2' }
      end

      it 'parses annotations' do
        expect(subject.size).to eq(2)
        expect(subject.map(&:label)).to eq(%w[foo bar])
        expect(subject.map(&:value)).to eq(%w[value1 value2])
      end
    end
  end

  describe '#environment' do
    subject { alert.environment }

    context 'without gitlab_alert' do
      it { is_expected.to be_nil }
    end

    context 'with gitlab alert' do
      include_context 'gitlab alert'

      it { is_expected.to eq(gitlab_alert.environment) }
    end
  end

  describe '#starts_at' do
    subject { alert.starts_at }

    context 'with empty startsAt' do
      before do
        payload['startsAt'] = nil
      end

      it { is_expected.to be_nil }
    end

    context 'with invalid startsAt' do
      before do
        payload['startsAt'] = 'invalid'
      end

      it { is_expected.to be_nil }
    end

    context 'with payload' do
      let(:time) { Time.now.change(usec: 0) }

      before do
        payload['startsAt'] = time.rfc3339
      end

      it { is_expected.to eq(time) }
    end
  end

  describe '#full_query' do
    using RSpec::Parameterized::TableSyntax

    subject { alert.full_query }

    where(:generator_url, :expected_query) do
      nil | nil
      'http://localhost' | nil
      'invalid url' | nil
      'http://localhost:9090/graph?g1.expr=vector%281%29' | nil
      'http://localhost:9090/graph?g0.expr=vector%281%29' | 'vector(1)'
    end

    with_them do
      before do
        payload['generatorURL'] = generator_url
      end

      it { is_expected.to eq(expected_query) }
    end

    context 'with gitlab alert' do
      include_context 'gitlab alert'
      include_context 'full query'

      it { is_expected.to eq(gitlab_alert.full_query) }
    end
  end

  describe '#y_label' do
    subject { alert.y_label }

    it_behaves_like 'parse payload', 'annotations/gitlab_y_label'

    context 'when y_label is not included in the payload' do
      it_behaves_like 'parse payload', 'annotations/title'
    end
  end

  describe '#alert_markdown' do
    subject { alert.alert_markdown }

    it_behaves_like 'parse payload', 'annotations/gitlab_incident_markdown'
  end

  describe '#gitlab_fingerprint' do
    subject { alert.gitlab_fingerprint }

    context 'when the alert is a GitLab managed alert' do
      include_context 'gitlab alert'

      it 'returns a fingerprint' do
        plain_fingerprint = [alert.metric_id, alert.starts_at_raw].join('/')

        is_expected.to eq(Digest::SHA1.hexdigest(plain_fingerprint))
      end
    end

    context 'when the alert is from self managed Prometheus' do
      include_context 'full query'

      it 'returns a fingerprint' do
        plain_fingerprint = [alert.starts_at_raw, alert.title, alert.full_query].join('/')

        is_expected.to eq(Digest::SHA1.hexdigest(plain_fingerprint))
      end
    end
  end

  describe '#valid?' do
    before do
      payload.update(
        'annotations' => { 'title' => 'some title' },
        'startsAt' => Time.now.rfc3339
      )
    end

    subject { alert }

    it { is_expected.to be_valid }

    context 'without project' do
      let(:project) { nil }

      it { is_expected.not_to be_valid }
    end

    context 'without starts_at' do
      before do
        payload['startsAt'] = nil
      end

      it { is_expected.not_to be_valid }
    end
  end
end
