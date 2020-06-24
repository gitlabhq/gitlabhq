# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Serverless::Domain do
  let(:function_name) { 'test-function' }
  let(:pages_domain_name) { 'serverless.gitlab.io' }
  let(:pages_domain) { create(:pages_domain, :instance_serverless, domain: pages_domain_name) }
  let!(:serverless_domain_cluster) { create(:serverless_domain_cluster, uuid: 'abcdef12345678', pages_domain: pages_domain) }
  let(:valid_cluster_uuid) { 'aba1cdef123456f278' }
  let(:invalid_cluster_uuid) { 'aba1cdef123456f178' }
  let!(:environment) { create(:environment, name: 'test') }

  let(:valid_uri) { "https://#{function_name}-#{valid_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{pages_domain_name}" }
  let(:valid_fqdn) { "#{function_name}-#{valid_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{pages_domain_name}" }
  let(:invalid_uri) { "https://#{function_name}-#{invalid_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{pages_domain_name}" }

  shared_examples 'a valid Domain' do
    describe '#uri' do
      it 'matches valid URI' do
        expect(subject.uri.to_s).to eq valid_uri
      end
    end

    describe '#function_name' do
      it 'returns function_name' do
        expect(subject.function_name).to eq function_name
      end
    end

    describe '#serverless_domain_cluster' do
      it 'returns serverless_domain_cluster' do
        expect(subject.serverless_domain_cluster).to eq serverless_domain_cluster
      end
    end

    describe '#environment' do
      it 'returns environment' do
        expect(subject.environment).to eq environment
      end
    end
  end

  describe '.new' do
    context 'with valid arguments' do
      subject do
        described_class.new(
          function_name: function_name,
          serverless_domain_cluster: serverless_domain_cluster,
          environment: environment
        )
      end

      it_behaves_like 'a valid Domain'
    end

    context 'with invalid arguments' do
      subject do
        described_class.new(
          function_name: function_name,
          environment: environment
        )
      end

      it { is_expected.not_to be_valid }
    end

    context 'with nil cluster argument' do
      subject do
        described_class.new(
          function_name: function_name,
          serverless_domain_cluster: nil,
          environment: environment
        )
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe '.generate_uuid' do
    it 'has 14 characters' do
      expect(described_class.generate_uuid.length).to eq(described_class::UUID_LENGTH)
    end

    it 'consists of only hexadecimal characters' do
      expect(described_class.generate_uuid).to match(/\A\h+\z/)
    end

    it 'uses random characters' do
      uuid = 'abcd1234567890'

      expect(SecureRandom).to receive(:hex).with(described_class::UUID_LENGTH / 2).and_return(uuid)
      expect(described_class.generate_uuid).to eq(uuid)
    end
  end
end
