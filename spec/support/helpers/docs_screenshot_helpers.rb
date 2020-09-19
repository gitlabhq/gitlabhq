# frozen_string_literal: true

require 'fileutils'
require 'mini_magick'

module DocsScreenshotHelpers
  extend ActiveSupport::Concern

  def set_crop_data(element, padding)
    @crop_element = element
    @crop_padding = padding
  end

  def crop_image_screenshot(path)
    element_rect = @crop_element.evaluate_script("this.getBoundingClientRect()")

    width = element_rect['width'] + (@crop_padding * 2)
    height = element_rect['height'] + (@crop_padding * 2)

    x = element_rect['x'] - @crop_padding
    y = element_rect['y'] - @crop_padding

    image = MiniMagick::Image.new(path)
    image.crop "#{width}x#{height}+#{x}+#{y}"
  end

  included do |base|
    after do |example|
      filename = "#{example.description}.png"
      path = File.expand_path(filename, 'doc/')
      page.save_screenshot(path)

      if @crop_element
        crop_image_screenshot(path)
        set_crop_data(nil, nil)
      end
    end
  end
end
