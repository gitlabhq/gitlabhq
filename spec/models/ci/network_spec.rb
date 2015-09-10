require 'spec_helper'

describe Network do
  let(:network) { Network.new }

  describe :enable_ci do
    subject { network.enable_ci '', '', '' }

    context 'on success' do
      before do
        response = double
        allow(response).to receive(:code) { 200 }
        allow(network.class).to receive(:put) { response }
      end

      it { is_expected.to be_truthy }
    end

    context 'on failure' do
      before do
        response = double
        allow(response).to receive(:code) { 404 }
        allow(network.class).to receive(:put) { response }
      end

      it { is_expected.to be_nil }
    end
  end

  describe :disable_ci do
    let(:response) { double }
    subject { network.disable_ci '', '' }

    context 'on success' do
      let(:parsed_response) { 'parsed' }
      before do
        allow(response).to receive(:code) { 200 }
        allow(response).to receive(:parsed_response) { parsed_response }
        allow(network.class).to receive(:delete) { response }
      end

      it { is_expected.to equal(parsed_response) }
    end

    context 'on failure' do
      before do
        allow(response).to receive(:code) { 404 }
        allow(network.class).to receive(:delete) { response }
      end

      it { is_expected.to be_nil }
    end
  end
end
