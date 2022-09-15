# frozen_string_literal: true

require_relative "lib/microsoft_graph_mailer/version"

Gem::Specification.new do |spec|
  spec.name = "microsoft_graph_mailer"
  spec.version = MicrosoftGraphMailer::VERSION
  spec.authors = ["Bogdan Denkovych"]
  spec.email = ["bdenkovych@gitlab.com"]

  spec.summary = "Allows delivery of emails using Microsoft Graph API with OAuth 2.0 client credentials flow"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/microsoft_graph_mailer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/microsoft_graph_mailer"

  spec.files = Dir["lib/**/*.rb"] + ["LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "mail", "~> 2.7"
  spec.add_runtime_dependency "oauth2", [">= 1.4.4", "< 3"]

  spec.add_development_dependency "debug", ">= 1.0.0"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "rspec", "~> 3.11.0"
  spec.add_development_dependency "webmock", "~> 3.18.1"
end
