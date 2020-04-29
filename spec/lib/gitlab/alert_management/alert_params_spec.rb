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
end
