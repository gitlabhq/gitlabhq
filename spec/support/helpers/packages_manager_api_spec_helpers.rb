# frozen_string_literal: true

module PackagesManagerApiSpecHelpers
  def build_headers_for_auth_type(auth)
    case auth
    when :oauth
      build_token_auth_header(token.plaintext_token)
    when :personal_access_token
      build_token_auth_header(personal_access_token.token)
    when :job_token
      build_token_auth_header(job.token)
    when :deploy_token
      build_token_auth_header(deploy_token.token)
    else
      {}
    end
  end

  def build_jwt(personal_access_token, secret: jwt_secret, user_id: nil)
    JSONWebToken::HMACToken.new(secret).tap do |jwt|
      jwt['access_token'] = personal_access_token.token
      jwt['user_id'] = user_id || personal_access_token.user_id
    end
  end

  def build_jwt_from_job(job, secret: jwt_secret)
    JSONWebToken::HMACToken.new(secret).tap do |jwt|
      jwt['access_token'] = job.token
      jwt['user_id'] = job.user.id
    end
  end

  def build_jwt_from_deploy_token(deploy_token, secret: jwt_secret)
    JSONWebToken::HMACToken.new(secret).tap do |jwt|
      jwt['access_token'] = deploy_token.token
      jwt['user_id'] = deploy_token.username
    end
  end

  def set_npm_package_requests_forwarding(request_forward, scope)
    params = { attribute: 'npm_package_requests_forwarding', return_value: request_forward }

    if %i[instance group].include?(scope)
      allow_fetch_application_setting(**params)
    else
      allow_fetch_cascade_application_setting(**params)
    end
  end

  def set_package_name_from_group_and_package_type(package_name_type, group)
    case package_name_type
    when :scoped_naming_convention
      "@#{group.path}/scoped-package"
    when :scoped_no_naming_convention
      '@any-scope/scoped-package'
    when :unscoped
      'unscoped-package'
    when :non_existing
      'non-existing-package'
    end
  end

  def temp_file(package_tmp, content: nil)
    upload_path = ::Packages::PackageFileUploader.workhorse_local_upload_path
    file_path = "#{upload_path}/#{package_tmp}"

    FileUtils.mkdir_p(upload_path)
    content ? FileUtils.cp(content, file_path) : File.write(file_path, 'test')

    UploadedFile.new(file_path, filename: File.basename(file_path))
  end
end
