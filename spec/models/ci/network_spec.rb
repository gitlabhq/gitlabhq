require 'spec_helper'

describe Network do
  let(:network) { Network.new }

  describe :enable_ci do
    subject { network.enable_ci '', '', '' }

    context 'on success' do
      before do
        response = double
        response.stub(:code) { 200 }
        network.class.stub(:put) { response }
      end

      it { should be_true }
    end

    context 'on failure' do
      before do
        response = double
        response.stub(:code) { 404 }
        network.class.stub(:put) { response }
      end

      it { should be_nil }
    end
  end

  describe :disable_ci do
    let(:response) { double }
    subject { network.disable_ci '', '' }

    context 'on success' do
      let(:parsed_response) { 'parsed' }
      before do
        response.stub(:code) { 200 }
        response.stub(:parsed_response) { parsed_response }
        network.class.stub(:delete) { response }
      end

      it { should equal(parsed_response) }
    end

    context 'on failure' do
      before do
        response.stub(:code) { 404 }
        network.class.stub(:delete) { response }
      end

      it { should be_nil }
    end
  end
end
