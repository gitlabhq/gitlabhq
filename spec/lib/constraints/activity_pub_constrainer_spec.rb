# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Constraints::ActivityPubConstrainer, feature_category: :groups_and_projects do
  subject(:constraint) { described_class.new }

  describe '#matches?' do
    subject { constraint.matches?(request) }

    let(:request) { ActionDispatch::Request.new(headers) }

    ['application/ld+json; profile="https://www.w3.org/ns/activitystreams"', 'application/activity+json'].each do |mime|
      context "when Accept header is #{mime}" do
        let(:headers) { { 'HTTP_ACCEPT' => mime } }

        it 'matches the header' do
          is_expected.to be_truthy
        end
      end

      context "when Content-Type header is #{mime}" do
        let(:headers) { { 'CONTENT_TYPE' => mime } }

        it 'matches the header' do
          is_expected.to be_truthy
        end
      end
    end

    context 'when Accept and Content-Type headers are missing' do
      let(:headers) { {} }

      it 'does not match' do
        is_expected.to be_falsey
      end
    end
  end
end
