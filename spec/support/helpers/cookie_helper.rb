# Helper for setting cookies in Selenium/WebDriver
#
module CookieHelper
  def set_cookie(name, value, options = {})
    case page.driver
    when Capybara::RackTest::Driver
      rack_set_cookie(name, value)
    else
      selenium_set_cookie(name, value, options)
    end
  end

  def selenium_set_cookie(name, value, options = {})
    # Selenium driver will not set cookies for a given domain when the browser is at `about:blank`.
    # It also doesn't appear to allow overriding the cookie path. loading `/` is the most inclusive.
    visit options.fetch(:path, '/') unless on_a_page?
    page.driver.browser.manage.add_cookie(name: name, value: value, **options)
  end

  def rack_set_cookie(name, value)
    page.driver.browser.set_cookie("#{name}=#{value}")
  end

  def get_cookie(name)
    page.driver.browser.manage.cookie_named(name)
  end

  private

  def on_a_page?
    current_url = Capybara.current_session.driver.browser.current_url
    current_url && current_url != '' && current_url != 'about:blank' && current_url != 'data:,'
  end
end
