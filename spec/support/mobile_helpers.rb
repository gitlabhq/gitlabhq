module MobileHelpers
  def resize_screen_sm
    resize_window(900, 768)
  end

  def restore_window_size
    resize_window(1366, 768)
  end

  def resize_window(width, height)
    page.driver.resize_window width, height
  end
end
