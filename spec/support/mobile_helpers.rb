module MobileHelpers
  def resize_screen_xs
    resize_window(767, 768)
  end

  def resize_screen_sm
    resize_window(900, 768)
  end

  def restore_window_size
    resize_window(1366, 768)
  end

  def resize_window(width, height)
    Capybara.current_session.current_window.resize_to(width, height)
  end
end
