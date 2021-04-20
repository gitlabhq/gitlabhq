# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

module Tooling
  class MergeRequest
    GITLAB_API_URL_TEMPLATE = 'https://gitlab.com/api/v4/projects/%{project_path}/merge_requests'

    def self.for(branch:, project_path:)
      url = format(GITLAB_API_URL_TEMPLATE, { project_path: URI.encode_www_form_component(project_path) })

      conn = Faraday.new(url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end

      response = conn.get do |req|
        req.params[:source_branch] = branch
        req.params[:order_by] = 'updated_at'
        req.params[:sort] = 'desc'
      end

      new(response.body.first)
    end

    attr_reader :merge_request

    def initialize(merge_request)
      @merge_request = merge_request
    end

    def iid
      merge_request['iid']
    end
  end
end
