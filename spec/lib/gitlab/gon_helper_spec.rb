# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GonHelper do
  let(:helper) do
    Class.new do
      include Gitlab::GonHelper

      def current_user
        nil
      end
    end.new
  end

  describe '#add_gon_variables' do
    let(:gon) { double('gon').as_null_object }
    let(:https) { true }

    before do
      allow(helper).to receive(:gon).and_return(gon)
      stub_config_setting(https: https)
    end

    context 'when HTTPS is enabled' do
      it 'sets the secure flag to true' do
        expect(gon).to receive(:secure=).with(true)

        helper.add_gon_variables
      end
    end

    context 'when HTTP is enabled' do
      let(:https) { false }

      it 'sets the secure flag to false' do
        expect(gon).to receive(:secure=).with(false)

        helper.add_gon_variables
      end
    end
  end

  describe '#push_frontend_feature_flag' do
    before do
      skip_feature_flags_yaml_validation
    end

    it 'pushes a feature flag to the frontend' do
      gon = class_double('Gon')
      thing = stub_feature_flag_gate('thing')

      stub_feature_flags(my_feature_flag: thing)

      allow(helper)
        .to receive(:gon)
        .and_return(gon)

      expect(gon)
        .to receive(:push)
        .with({ features: { 'myFeatureFlag' => true } }, true)

      helper.push_frontend_feature_flag(:my_feature_flag, thing)
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
