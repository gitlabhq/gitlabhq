# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Serverless::Service do
  let(:cluster) { create(:cluster) }
  let(:environment) { create(:environment) }
  let(:attributes) do
    {
      'apiVersion' => 'serving.knative.dev/v1alpha1',
      'kind' => 'Service',
      'metadata' => {
        'creationTimestamp' => '2019-10-22T21:19:13Z',
        'name' => 'kubetest',
        'namespace' => 'project1-1-environment1'
      },
      'spec' => {
        'runLatest' => {
          'configuration' => {
            'build' => {
              'template' => {
                'name' => 'some-image'
              }
            }
          }
        }
      },
      'environment_scope' => '*',
      'cluster' => cluster,
      'environment' => environment,
      'podcount' => 0
    }
  end

  it 'exposes methods extracting data from the attributes hash' do
    service = Gitlab::Serverless::Service.new(attributes)

    expect(service.name).to eq('kubetest')
    expect(service.namespace).to eq('project1-1-environment1')
    expect(service.environment_scope).to eq('*')
    expect(service.podcount).to eq(0)
    expect(service.created_at).to eq(DateTime.parse('2019-10-22T21:19:13Z'))
    expect(service.image).to eq('some-image')
    expect(service.cluster).to eq(cluster)
    expect(service.environment).to eq(environment)
  end

  it 'returns nil for missing attributes' do
    service = Gitlab::Serverless::Service.new({})

    [:name, :namespace, :environment_scope, :cluster, :podcount, :created_at, :image, :description, :url, :environment].each do |method|
      expect(service.send(method)).to be_nil
    end
  end

  describe '#description' do
    it 'extracts the description in knative 7 format if available' do
      attributes = {
        'spec' => {
          'template' => {
            'metadata' => {
              'annotations' => {
                'Description' => 'some description'
              }
            }
          }
        }
      }
      service = Gitlab::Serverless::Service.new(attributes)

      expect(service.description).to eq('some description')
    end

    it 'extracts the description in knative 5/6 format if 7 is not available' do
      attributes = {
        'spec' => {
          'runLatest' => {
            'configuration' => {
              'revisionTemplate' => {
                'metadata' => {
                  'annotations' => {
                    'Description' => 'some description'
                  }
                }
              }
            }
          }
        }
      }
      service = Gitlab::Serverless::Service.new(attributes)

      expect(service.description).to eq('some description')
    end
  end

  describe '#url' do
    let(:serverless_domain) { instance_double(::Serverless::Domain, uri: URI('https://proxy.example.com')) }

    it 'returns proxy URL if cluster has serverless domain' do
      # cluster = create(:cluster)
      knative = create(:clusters_applications_knative, :installed, cluster: cluster)
      create(:serverless_domain_cluster, clusters_applications_knative_id: knative.id)
      service = Gitlab::Serverless::Service.new(attributes.merge('cluster' => cluster))

      expect(::Serverless::Domain).to receive(:new).with(
        function_name: service.name,
        serverless_domain_cluster: service.cluster.serverless_domain,
        environment: service.environment
      ).and_return(serverless_domain)

      expect(service.url).to eq('https://proxy.example.com')
    end

    it 'returns the URL from the knative 6/7 format' do
      attributes = {
        'status' => {
          'url' => 'https://example.com'
        }
      }
      service = Gitlab::Serverless::Service.new(attributes)

      expect(service.url).to eq('https://example.com')
    end

    it 'returns the URL from the knative 5 format' do
      attributes = {
        'status' => {
          'domain' => 'example.com'
        }
      }
      service = Gitlab::Serverless::Service.new(attributes)

      expect(service.url).to eq('http://example.com')
    end
  end
end
