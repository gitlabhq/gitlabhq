# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MIME types initializer', feature_category: :api do
  describe 'JSON MIME type registration' do
    it 'registers application/vnd.docker.distribution.events.v1+json as JSON' do
      docker_json_type = Mime::Type.lookup('application/vnd.docker.distribution.events.v1+json')

      expect(docker_json_type).to eq(Mime[:json])
    end

    it 'includes docker distribution events in JSON MIME type synonyms' do
      json_mime = Mime::Type.lookup('application/json')

      expect(Mime::Type.parse('application/vnd.docker.distribution.events.v1+json')).to include(json_mime)
    end
  end
end
