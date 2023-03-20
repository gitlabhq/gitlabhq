# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::GenerateTokenService, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:service) { described_class.new(attr: attr) }
  let(:token) { 'token' }
  let(:digest) { Devise.token_generator.digest(User, attr, token) }

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
  end
end
