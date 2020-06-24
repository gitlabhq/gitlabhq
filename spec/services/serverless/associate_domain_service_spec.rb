# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Serverless::AssociateDomainService do
  subject { described_class.new(knative, pages_domain_id: pages_domain_id, creator: creator) }

  let(:sdc) { create(:serverless_domain_cluster, pages_domain: create(:pages_domain, :instance_serverless)) }
  let(:knative) { sdc.knative }
  let(:creator) { sdc.creator }
  let(:pages_domain_id) { sdc.pages_domain_id }

  context 'when the domain is unchanged' do
    let(:creator) { create(:user) }

    it 'does not update creator' do
      expect { subject.execute }.not_to change { sdc.reload.creator }
    end
  end

  context 'when domain is changed to nil' do
    let(:pages_domain_id) { nil }
    let(:creator) { create(:user) }

    it 'removes the association between knative and the domain' do
      expect { subject.execute }.to change { knative.reload.pages_domain }.from(sdc.pages_domain).to(nil)
    end

    it 'does not attempt to update creator' do
      expect { subject.execute }.not_to raise_error
    end
  end

  context 'when a new domain is associated' do
    let(:pages_domain_id) { create(:pages_domain, :instance_serverless).id }
    let(:creator) { create(:user) }

    it 'creates an association with the domain' do
      expect { subject.execute }.to change { knative.pages_domain.id }.from(sdc.pages_domain.id).to(pages_domain_id)
    end

    it 'updates creator' do
      expect { subject.execute }.to change { sdc.reload.creator }.from(sdc.creator).to(creator)
    end
  end

  context 'when knative is not authorized to use the pages domain' do
    let(:pages_domain_id) { create(:pages_domain).id }

    before do
      expect(knative).to receive(:available_domains).and_return(PagesDomain.none)
    end

    it 'sets pages_domain_id to nil' do
      expect { subject.execute }.to change { knative.reload.pages_domain }.from(sdc.pages_domain).to(nil)
    end
  end

  context 'when knative hostname is nil' do
    let(:knative) { build(:clusters_applications_knative, hostname: nil) }

    it 'sets hostname to a placeholder value' do
      expect { subject.execute }.to change { knative.hostname }.to('example.com')
    end
  end

  context 'when knative hostname exists' do
    let(:knative) { build(:clusters_applications_knative, hostname: 'hostname.com') }

    it 'does not change hostname' do
      expect { subject.execute }.not_to change { knative.hostname }
    end
  end
end
