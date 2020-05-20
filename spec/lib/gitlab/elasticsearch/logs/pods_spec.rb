# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elasticsearch::Logs::Pods do
  let(:client) { Elasticsearch::Transport::Client }

  let(:es_query) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/pods_query.json'), symbolize_names: true) }
  let(:es_response) { Gitlab::Json.parse(fixture_file('lib/elasticsearch/pods_response.json')) }
  let(:namespace) { "autodevops-deploy-9-production" }

  subject { described_class.new(client) }

  describe '#pods' do
    it 'returns the pods' do
      expect(client).to receive(:search).with(body: es_query).and_return(es_response)

      result = subject.pods(namespace)
      expect(result).to eq([
        {
          name: "runner-gitlab-runner-7bbfb5dcb5-p6smb",
          container_names: %w[runner-gitlab-runner]
        },
        {
          name: "elastic-stack-elasticsearch-master-1",
          container_names: %w[elasticsearch chown sysctl]
        },
        {
          name: "ingress-nginx-ingress-controller-76449bcc8d-8qgl6",
          container_names: %w[nginx-ingress-controller]
        }
     ])
    end
  end
end
