# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GonHelper do
  let(:helper) do
    Class.new do
      include Gitlab::GonHelper
    end.new
  end

  describe '#push_frontend_feature_flag' do
    it 'pushes a feature flag to the frontend' do
      gon = instance_double('gon')

      allow(helper)
        .to receive(:gon)
        .and_return(gon)

      expect(Feature)
        .to receive(:enabled?)
        .with(:my_feature_flag, 10)
        .and_return(true)

      expect(gon)
        .to receive(:push)
        .with({ features: { 'myFeatureFlag' => true } }, true)

      helper.push_frontend_feature_flag(:my_feature_flag, 10)
    end
  end

  describe '#default_avatar_url' do
    it 'returns an absolute URL' do
      url = helper.default_avatar_url

      expect(url).to match(/^http/)
      expect(url).to match(/no_avatar.*png$/)
    end
  end
end
