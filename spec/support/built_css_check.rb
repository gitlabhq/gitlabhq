# frozen_string_literal: true

# CSS is built by Node (`yarn build:css`), not by Sprockets. In a checkout that never
# built it, resolving a stylesheet makes Sprockets compile the `.scss` itself and raise
# `LoadError: cannot load such file -- sass`.
RSpec.configure do |config|
  registered = false

  %i[controller request feature mailer view].each do |type|
    config.when_first_matching_example_defined(type: type) do
      next if registered

      registered = true

      config.before(:suite) do
        # The same helper `add_gon_variables` uses: with Vite enabled it reads the Vite
        # manifest and never touches Sprockets, so only Sprockets runs can abort here.
        ApplicationController.helpers.universal_path_to_stylesheet('emoji_sprites')
      rescue LoadError => e
        raise unless e.path == 'sass'

        abort <<~MESSAGE
          Controller, request, feature, mailer, and view specs need the application CSS
          to have been built once, or rendering HTML fails with the misleading error
          `LoadError: cannot load such file -- sass`.

          Build it with:

            yarn build:css

          then run RSpec again.
        MESSAGE
      end
    end
  end
end
