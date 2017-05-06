require 'spec_helper'

describe BuildActionEntity do
  let(:build) { create(:ci_build, name: 'test_build') }
  let(:request) { double('request') }

  let(:entity) do
    described_class.new(build, request: spy('request'))
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains original build name' do
      expect(subject[:name]).to eq 'test_build'
    end

    it 'contains path to the action play' do
      expect(subject[:path]).to include "builds/#{build.id}/play"
    end

    it 'contains whether it is playable' do
      expect(subject[:playable]).to eq build.playable?
    end
  end
end
