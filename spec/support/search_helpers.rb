module SearchHelpers
  def select_filter(name)
    find(:xpath, "//ul[contains(@class, 'search-filter')]//a[contains(.,'#{name}')]").click
  end
end
