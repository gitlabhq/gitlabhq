# frozen_string_literal: true

module RubygemsHelpers
  def gem_from_file(file)
    full_path = File.expand_path(
      Rails.root.join('spec', 'fixtures', 'packages', 'rubygems', file.filename)
    )

    Gem::Package.new(File.open(full_path))
  end
end
