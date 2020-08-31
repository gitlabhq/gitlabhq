# frozen_string_literal: true

module Tooling
  module Image
    # Determine the tolerance till when we run pngquant in a loop
    TOLERANCE = 10000

    def self.check_executables
      unless system('pngquant --version', out: File::NULL)
        warn(
          'Error: pngquant executable was not detected in the system.',
          'Download pngquant at https://pngquant.org/ and place the executable in /usr/local/bin'
        )
        abort
      end

      unless system('gm version', out: File::NULL)
        warn(
          'Error: gm executable was not detected in the system.',
          'Please install imagemagick: brew install imagemagick or sudo apt install imagemagick'
        )
        abort
      end
    end

    def self.compress_image(file, keep_original = false)
      check_executables

      compressed_file = "#{file}.compressed"
      FileUtils.copy(file, compressed_file)

      pngquant_file = PngQuantizator::Image.new(compressed_file)

      # Run the image repeatedly through pngquant until
      # the change in file size is within TOLERANCE
      # or the loop count is above 1000
      1000.times do
        before = File.size(compressed_file)
        pngquant_file.quantize!
        after = File.size(compressed_file)
        break if before - after <= TOLERANCE
      end

      savings = File.size(file) - File.size(compressed_file)
      is_uncompressed = savings > TOLERANCE

      if is_uncompressed && !keep_original
        FileUtils.copy(compressed_file, file)
      end

      FileUtils.remove(compressed_file)

      [is_uncompressed, savings]
    end
  end
end
