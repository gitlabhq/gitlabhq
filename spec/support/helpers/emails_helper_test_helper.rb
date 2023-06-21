# frozen_string_literal: true

module EmailsHelperTestHelper
  def default_header_logo
    %r{<img alt="GitLab" src="http://test.host/images/mailers/gitlab_logo\.(?:gif|png)" width="\d+" height="\d+" />}
  end
end

EmailsHelperTestHelper.prepend_mod
