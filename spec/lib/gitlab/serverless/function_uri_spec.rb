# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Serverless::FunctionURI do
  let(:function) { 'test-function' }
  let(:domain) { 'serverless.gitlab.io' }
  let(:pages_domain) { create(:pages_domain, :instance_serverless, domain: domain) }
  let!(:cluster) { create(:serverless_domain_cluster, uuid: 'abcdef12345678', pages_domain: pages_domain) }
  let(:valid_cluster) { 'aba1cdef123456f278' }
  let(:invalid_cluster) { 'aba1cdef123456f178' }
  let!(:environment) { create(:environment, name: 'test') }

  let(:valid_uri) { "https://#{function}-#{valid_cluster}#{"%x" % environment.id}-#{environment.slug}.#{domain}" }
  let(:valid_fqdn) { "#{function}-#{valid_cluster}#{"%x" % environment.id}-#{environment.slug}.#{domain}" }
  let(:invalid_uri) { "https://#{function}-#{invalid_cluster}#{"%x" % environment.id}-#{environment.slug}.#{domain}" }

  shared_examples 'a valid FunctionURI class' do
    describe '#to_s' do
      it 'matches valid URI' do
        expect(subject.to_s).to eq valid_uri
      end
    end

    describe '#function' do
      it 'returns function' do
        expect(subject.function).to eq function
      end
    end

    describe '#cluster' do
      it 'returns cluster' do
        expect(subject.cluster).to eq cluster
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
      subject { described_class.new(function: function, cluster: cluster, environment: environment) }

      it_behaves_like 'a valid FunctionURI class'
    end

    context 'with invalid arguments' do
      subject { described_class.new(function: function, environment: environment) }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.parse' do
    context 'with valid URI' do
      subject { described_class.parse(valid_uri) }

      it_behaves_like 'a valid FunctionURI class'
    end

    context 'with valid FQDN' do
      subject { described_class.parse(valid_fqdn) }

      it_behaves_like 'a valid FunctionURI class'
    end

    context 'with invalid URI' do
      subject { described_class.parse(invalid_uri) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
