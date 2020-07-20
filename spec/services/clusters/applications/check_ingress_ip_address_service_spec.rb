# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::CheckIngressIpAddressService do
  include ExclusiveLeaseHelpers

  let(:application) { create(:clusters_applications_ingress, :installed) }
  let(:service) { described_class.new(application) }
  let(:kubeclient) { double(::Kubeclient::Client, get_service: kube_service) }
  let(:lease_key) { "check_ingress_ip_address_service:#{application.id}" }

  let(:ingress) do
    [
      {
        ip: '111.222.111.222',
        hostname: 'localhost.localdomain'
      }
    ]
  end

  let(:kube_service) do
    ::Kubeclient::Resource.new(
      {
          status: {
              loadBalancer: {
                  ingress: ingress
              }
          }
      }
    )
  end

  subject { service.execute }

  before do
    stub_exclusive_lease(lease_key, timeout: 15.seconds.to_i)
    allow(application.cluster).to receive(:kubeclient).and_return(kubeclient)
  end

  include_examples 'check ingress ip executions', :clusters_applications_ingress

  include_examples 'check ingress ip executions', :clusters_applications_knative
end
