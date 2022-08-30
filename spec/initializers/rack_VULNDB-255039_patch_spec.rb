# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rack VULNDB-255039' do
  context 'when handling query params in GET requests' do
    it 'does not treat semicolons as query delimiters' do
      env = ::Rack::MockRequest.env_for('http://gitlab.com?a=b;c=1')

      query_hash = ::Rack::Request.new(env).GET

      # Prior to this patch, this was splitting around the semicolon, which
      # would return {"a"=>"b", "c"=>"1"}
      expect(query_hash).to eq({ "a" => "b;c=1" })
    end
  end
end
