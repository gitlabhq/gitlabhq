# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseSerializer do
  let(:user) { build_stubbed(:user) }

  subject { described_class.new.represent(resource, current_user: user) }

  describe '#represent' do
    context 'when a single object is being serialized' do
      let(:resource) { build_stubbed(:release) }

      it 'serializes the label object' do
        expect(subject[:tag]).to eq resource.tag
      end

      it 'does not expose git-sha as sensitive information' do
        expect(subject[:sha]).to be_nil
      end
    end

    context 'when multiple objects are being serialized' do
      let(:resource) { build_stubbed_list(:release, 3) }

      it 'serializes the array of releases' do
        expect(subject.size).to eq(3)
      end
    end
  end
end
