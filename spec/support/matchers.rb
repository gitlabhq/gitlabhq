RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual != nil
    actual.id == ValidCommit::ID
    actual.message == ValidCommit::MESSAGE
    actual.author.name == ValidCommit::AUTHOR_FULL_NAME
  end
end

RSpec::Matchers.define :be_allowed_for do |user|
  match do |url|
    include UrlAccess
    url_allowed?(user, url)
  end
end

RSpec::Matchers.define :be_denied_for do |user|
  match do |url|
    include UrlAccess
    url_denied?(user, url)
  end
end

RSpec::Matchers.define :be_404_for do |user|
  match do |url|
    include UrlAccess
    url_404?(user, url)
  end
end

module UrlAccess
  def url_allowed?(user, url)
    emulate_user(user)
    visit url
    (page.status_code != 404 && current_path != new_user_session_path)
  end

  def url_denied?(user, url)
    emulate_user(user)
    visit url
    (page.status_code == 404 || current_path == new_user_session_path)
  end

  def url_404?(user, url)
    emulate_user(user)
    visit url
    page.status_code == 404
  end

  def emulate_user(user)
    user = case user
           when :user then Factory(:user)
           when :visitor then nil
           when :admin then Factory(:admin)
           else user
           end
    login_with(user) if user
  end
end
