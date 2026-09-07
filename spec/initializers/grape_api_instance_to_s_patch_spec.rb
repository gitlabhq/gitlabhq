# frozen_string_literal: true

require 'spec_helper'

# Pins what config/initializers/grape_api_instance_to_s_patch.rb preserves: a Grape API
# class must stringify to its own class name. See that file for why 3.2 breaks it.
RSpec.describe 'Grape API instance to_s patch', feature_category: :api do
  context 'with a named API class' do
    before do
      stub_const('MyTestApi', Class.new(::API::Base))
    end

    it 'stringifies to the class name', :aggregate_failures do
      expect(MyTestApi.to_s).to eq('MyTestApi')
      expect(MyTestApi.to_s).to eq(MyTestApi.name)
    end

    it 'interpolates to the class name' do
      expect("#{MyTestApi}::MAX_RESULTS").to eq('MyTestApi::MAX_RESULTS')
    end
  end

  context 'with real mounted API classes' do
    it 'stringifies each to its class name', :aggregate_failures do
      expect(::API::API.to_s).to eq('API::API')
      expect(::API::Search.to_s).to eq('API::Search')
      expect(Kernel.const_source_location(::API::Search.to_s)).to be_present
    end
  end

  context 'with an anonymous API class' do
    it 'falls back to the default Module#to_s' do
      klass = Class.new(::API::Base)

      expect(klass.to_s).to eq(Module.instance_method(:to_s).bind_call(klass))
    end
  end

  context 'with the anonymous instance a Grape::API subclass builds for itself' do
    # Grape de-duplicates remounted endpoints by comparing these by `to_s`.
    it 'still stringifies to the owning API class name' do
      stub_const('MyRemountableApi', Class.new(Grape::API))

      expect(MyRemountableApi.base_instance.to_s).to eq('MyRemountableApi')
    end
  end
end
