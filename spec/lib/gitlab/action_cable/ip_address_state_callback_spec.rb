# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ActionCable::IpAddressStateCallback, feature_category: :shared do
  describe '.wrapper' do
    let(:connection) do
      instance_double(
        ApplicationCable::Connection,
        request: instance_double(ActionDispatch::Request, ip: '1.1.1.1')
      )
    end

    it 'sets the IP address state in the inner block' do
      expect(Gitlab::IpAddressState.current).to be_nil

      instance_exec(
        nil,
        -> do
          expect(::Gitlab::IpAddressState.current).to eq('1.1.1.1')
        end,
        &described_class.wrapper
      )

      expect(Gitlab::IpAddressState.current).to be_nil
    end
  end
end
