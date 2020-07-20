# frozen_string_literal: true

# For specs which don't load Rails, provide a path to Rails root
module FastRailsRoot
  RAILS_ROOT = File.absolute_path("#{__dir__}/../../..")

  def rails_root_join(*args)
    File.join(RAILS_ROOT, *args)
  end
end
