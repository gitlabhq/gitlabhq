# frozen_string_literal: true

require 'spec_helper'

describe ::Serverless::DomainCluster do
  subject { create(:serverless_domain_cluster) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:pages_domain) }
    it { is_expected.to validate_presence_of(:knative) }

    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_length_of(:uuid).is_equal_to(Gitlab::Serverless::Domain::UUID_LENGTH) }
    it { is_expected.to validate_uniqueness_of(:uuid) }

    it 'validates that uuid has only hex characters' do
      subject = build(:serverless_domain_cluster, uuid: 'z1234567890123')
      subject.valid?

      expect(subject.errors[:uuid]).to include('only allows hex characters')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:pages_domain) }
    it { is_expected.to belong_to(:knative) }
    it { is_expected.to belong_to(:creator).optional }
  end

  describe 'uuid' do
    context 'when nil' do
      it 'generates a value by default' do
        attributes = build(:serverless_domain_cluster).attributes.merge(uuid: nil)
        expect(Gitlab::Serverless::Domain).to receive(:generate_uuid).and_call_original

        subject = Serverless::DomainCluster.new(attributes)

        expect(subject.uuid).not_to be_blank
      end
    end

    context 'when not nil' do
      it 'does not override the existing value' do
        uuid = 'abcd1234567890'
        expect(build(:serverless_domain_cluster, uuid: uuid).uuid).to eq(uuid)
      end
    end
  end

  describe 'domain' do
    it { is_expected.to respond_to(:domain) }
  end
end
