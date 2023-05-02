# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::GenerateTokenService, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:user) { build_stubbed(:user) }
  let(:service) { described_class.new(attr: attr, user: user) }
  let(:token) { 'token' }
  let(:digest) { service.send(:digest) }

  describe '#execute' do
    context 'with a valid attribute' do
      where(:attr) { [:unlock_token, :confirmation_token] }

      with_them do
        before do
          allow_next_instance_of(described_class) do |service|
            allow(service).to receive(:generate_token).and_return(token)
          end
        end

        it "returns a token and it's digest" do
          expect(service.execute).to eq([token, digest])
        end
      end
    end

    context 'with an invalid attribute' do
      let(:attr) { :xxx }

      it 'raises an error' do
        expect { service.execute }.to raise_error(ArgumentError, 'Invalid attribute')
      end
    end

    context 'when similar tokens are generated' do
      let(:attr) { :confirmation_token }

      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(:generate_token).and_return(token)
        end
      end

      it 'generates a unique digest' do
        second_service = described_class.new(attr: attr, user: build_stubbed(:user))

        expect(service.execute[1]).not_to eq(second_service.execute[1])
      end
    end
  end
end
