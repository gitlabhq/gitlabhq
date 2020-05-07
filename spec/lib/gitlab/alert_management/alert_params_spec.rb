# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::AlertManagement::AlertParams do
  let_it_be(:project) { create(:project, :repository, :private) }

  describe '.from_generic_alert' do
    let(:started_at) { Time.current.change(usec: 0).rfc3339 }
    let(:payload) do
      {
        'title' => 'Alert title',
        'description' => 'Description',
        'monitoring_tool' => 'Monitoring tool name',
        'service' => 'Service',
        'hosts' => ['gitlab.com'],
        'start_time' => started_at,
        'some' => { 'extra' => { 'payload' => 'here' } }
      }
    end

    subject { described_class.from_generic_alert(project: project, payload: payload) }

    it 'returns Alert compatible parameters' do
      is_expected.to eq(
        project_id: project.id,
        title: 'Alert title',
        description: 'Description',
        monitoring_tool: 'Monitoring tool name',
        service: 'Service',
        hosts: ['gitlab.com'],
        payload: payload,
        started_at: started_at
      )
    end

    context 'when there are no hosts in the payload' do
      let(:payload) { {} }

      it 'hosts param is an empty array' do
        expect(subject[:hosts]).to be_empty
      end
    end
  end

  describe '.from_prometheus_alert' do
    let(:payload) do
      {
        'status' => 'firing',
        'labels' => {
          'alertname' => 'GitalyFileServerDown',
          'channel' => 'gitaly',
          'pager' => 'pagerduty',
          'severity' => 's1'
        },
        'annotations' => {
          'description' => 'Alert description',
          'runbook' => 'troubleshooting/gitaly-down.md',
          'title' => 'Alert title'
        },
        'startsAt' => '2020-04-27T10:10:22.265949279Z',
        'endsAt' => '0001-01-01T00:00:00Z',
        'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1',
        'fingerprint' => 'b6ac4d42057c43c1'
      }
    end
    let(:parsed_alert) { Gitlab::Alerting::Alert.new(project: project, payload: payload) }

    subject { described_class.from_prometheus_alert(project: project, parsed_alert: parsed_alert) }

    it 'returns Alert-compatible params' do
      is_expected.to eq(
        project_id: project.id,
        title: 'Alert title',
        description: 'Alert description',
        monitoring_tool: 'Prometheus',
        payload: payload,
        started_at: parsed_alert.starts_at,
        ended_at: parsed_alert.ends_at,
        fingerprint: parsed_alert.gitlab_fingerprint
      )
    end
  end
end
