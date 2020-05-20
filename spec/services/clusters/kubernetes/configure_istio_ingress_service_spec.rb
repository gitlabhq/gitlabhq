# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::ConfigureIstioIngressService, '#execute' do
  include KubernetesHelpers

  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:api_url) { 'https://kubernetes.example.com' }
  let(:project) { cluster.project }
  let(:environment) { create(:environment, project: project) }
  let(:cluster_project) { cluster.cluster_project }
  let(:namespace) { "#{project.name}-#{project.id}-#{environment.slug}" }
  let(:kubeclient) { cluster.kubeclient }

  subject do
    described_class.new(
      cluster: cluster
    ).execute
  end

  before do
    stub_kubeclient_discover_istio(api_url)
    stub_kubeclient_create_secret(api_url, namespace: namespace)
    stub_kubeclient_put_secret(api_url, "#{namespace}-token", namespace: namespace)

    stub_kubeclient_get_secret(
      api_url,
      {
        metadata_name: "#{namespace}-token",
        token: Base64.encode64('sample-token'),
        namespace: namespace
      }
    )

    stub_kubeclient_get_secret(
      api_url,
      {
        metadata_name: 'istio-ingressgateway-ca-certs',
        namespace: 'istio-system'
      }
    )

    stub_kubeclient_get_secret(
      api_url,
      {
        metadata_name: 'istio-ingressgateway-certs',
        namespace: 'istio-system'
      }
    )

    stub_kubeclient_put_secret(api_url, 'istio-ingressgateway-ca-certs', namespace: 'istio-system')
    stub_kubeclient_put_secret(api_url, 'istio-ingressgateway-certs', namespace: 'istio-system')
    stub_kubeclient_get_gateway(api_url, 'knative-ingress-gateway', namespace: 'knative-serving')
    stub_kubeclient_put_gateway(api_url, 'knative-ingress-gateway', namespace: 'knative-serving')
  end

  context 'without a serverless_domain_cluster' do
    it 'configures gateway to use PASSTHROUGH' do
      subject

      expect(WebMock).to have_requested(:put, api_url + '/apis/networking.istio.io/v1alpha3/namespaces/knative-serving/gateways/knative-ingress-gateway').with(
        body: hash_including(
          apiVersion: "networking.istio.io/v1alpha3",
          kind: "Gateway",
          metadata: {
            generation: 1,
            labels: {
              "networking.knative.dev/ingress-provider" => "istio",
              "serving.knative.dev/release" => "v0.7.0"
            },
            name: "knative-ingress-gateway",
            namespace: "knative-serving",
            selfLink: "/apis/networking.istio.io/v1alpha3/namespaces/knative-serving/gateways/knative-ingress-gateway"
          },
          spec: {
            selector: {
              istio: "ingressgateway"
            },
            servers: [
              {
                hosts: ["*"],
                port: {
                  name: "http",
                  number: 80,
                  protocol: "HTTP"
                }
              },
              {
                hosts: ["*"],
                port: {
                  name: "https",
                  number: 443,
                  protocol: "HTTPS"
                },
                tls: {
                  mode: "PASSTHROUGH"
                }
              }
            ]
          }
        )
      )
    end
  end

  context 'with a serverless_domain_cluster' do
    let(:serverless_domain_cluster) { create(:serverless_domain_cluster) }
    let(:certificate) { OpenSSL::X509::Certificate.new(serverless_domain_cluster.certificate) }

    before do
      cluster.application_knative = serverless_domain_cluster.knative
    end

    it 'configures certificates' do
      subject

      expect(serverless_domain_cluster.reload.key).not_to be_blank
      expect(serverless_domain_cluster.reload.certificate).not_to be_blank

      expect(certificate.subject.to_s).to include(serverless_domain_cluster.knative.hostname)

      expect(certificate.not_before).to be_within(1.minute).of(Time.current)
      expect(certificate.not_after).to be_within(1.minute).of(Time.current + 1000.years)

      expect(WebMock).to have_requested(:put, api_url + '/api/v1/namespaces/istio-system/secrets/istio-ingressgateway-ca-certs').with(
        body: hash_including(
          metadata: {
            name: 'istio-ingressgateway-ca-certs',
            namespace: 'istio-system'
          },
          type: 'Opaque'
        )
      )

      expect(WebMock).to have_requested(:put, api_url + '/api/v1/namespaces/istio-system/secrets/istio-ingressgateway-certs').with(
        body: hash_including(
          metadata: {
            name: 'istio-ingressgateway-certs',
            namespace: 'istio-system'
          },
          type: 'kubernetes.io/tls'
        )
      )
    end

    it 'configures gateway to use MUTUAL' do
      subject

      expect(WebMock).to have_requested(:put, api_url + '/apis/networking.istio.io/v1alpha3/namespaces/knative-serving/gateways/knative-ingress-gateway').with(
        body: {
          apiVersion: "networking.istio.io/v1alpha3",
          kind: "Gateway",
          metadata: {
            generation: 1,
            labels: {
              "networking.knative.dev/ingress-provider" => "istio",
              "serving.knative.dev/release" => "v0.7.0"
            },
            name: "knative-ingress-gateway",
            namespace: "knative-serving",
            selfLink: "/apis/networking.istio.io/v1alpha3/namespaces/knative-serving/gateways/knative-ingress-gateway"
          },
          spec: {
            selector: {
              istio: "ingressgateway"
            },
            servers: [
              {
                hosts: ["*"],
                port: {
                  name: "http",
                  number: 80,
                  protocol: "HTTP"
                }
              },
              {
                hosts: ["*"],
                port: {
                  name: "https",
                  number: 443,
                  protocol: "HTTPS"
                },
                tls: {
                  mode: "MUTUAL",
                  privateKey: "/etc/istio/ingressgateway-certs/tls.key",
                  serverCertificate: "/etc/istio/ingressgateway-certs/tls.crt",
                  caCertificates: "/etc/istio/ingressgateway-ca-certs/cert.pem"
                }
              }
            ]
          }
        }
      )
    end
  end

  context 'when there is an error' do
    before do
      cluster.application_knative = create(:clusters_applications_knative)

      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:configure_passthrough).and_raise(error)
      end
    end

    context 'Kubeclient::HttpError' do
      let(:error) { Kubeclient::HttpError.new(404, nil, nil) }

      it 'puts Knative into an errored state' do
        subject

        expect(cluster.application_knative).to be_errored
        expect(cluster.application_knative.status_reason).to eq('Kubernetes error: 404')
      end
    end

    context 'StandardError' do
      let(:error) { RuntimeError.new('something went wrong') }

      it 'puts Knative into an errored state' do
        subject

        expect(cluster.application_knative).to be_errored
        expect(cluster.application_knative.status_reason).to eq('Failed to update.')
      end
    end
  end
end
