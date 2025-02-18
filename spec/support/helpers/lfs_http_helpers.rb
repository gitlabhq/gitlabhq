# frozen_string_literal: true

require_relative 'workhorse_helpers'

module LfsHttpHelpers
  include WorkhorseHelpers

  def authorize_ci_project
    ActionController::HttpAuthentication::Basic.encode_credentials('gitlab-ci-token', build.token)
  end

  def authorize_user
    ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
  end

  def authorize_deploy_key
    Gitlab::LfsToken.new(key, nil).basic_encoding
  end

  def authorize_user_key
    Gitlab::LfsToken.new(user, nil).basic_encoding
  end

  def authorize_deploy_token
    ActionController::HttpAuthentication::Basic.encode_credentials(deploy_token.username, deploy_token.token)
  end

  def post_lfs_json(url, body = nil, headers = nil)
    params = body.try(:to_json)
    headers = (headers || {}).merge('Content-Type' => LfsRequest::CONTENT_TYPE)

    post(url, params: params, headers: headers)
  end

  def batch_url(container)
    "#{container.http_url_to_repo}/info/lfs/objects/batch"
  end

  def objects_url(container, oid = nil, size = nil)
    File.join(["#{container.http_url_to_repo}/gitlab-lfs/objects", oid, size].compact.map(&:to_s))
  end

  def authorize_url(container, oid, size)
    File.join(objects_url(container, oid, size), 'authorize')
  end

  def download_body(objects)
    request_body('download', objects)
  end

  def upload_body(objects)
    request_body('upload', objects)
  end

  def request_body(operation, objects)
    {
      'operation' => operation,
      'objects' => Array.wrap(objects)
    }
  end
end
