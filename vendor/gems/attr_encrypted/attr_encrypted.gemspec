# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'attr_encrypted/version'

Gem::Specification.new do |s|
  s.name    = 'attr_encrypted'
  s.version = AttrEncrypted::Version.string

  s.summary     = 'GitLab fork of attr_encrypted'
  s.description = "Generates attr_accessors that encrypt and decrypt attributes transparently.\n\n
Forked from https://github.com/attr-encrypted/attr_encrypted."

  s.authors   = ['Sean Huber', 'S. Brent Faulkner', 'William Monk', 'Stephen Aghaulor']
  s.email    = ['seah@shuber.io', 'sbfaulkner@gmail.com', 'billy.monk@gmail.com', 'saghaulor@gmail.com']
  s.homepage = 'https://gitlab.com/gitlab-org/ruby/gems/attr_encrypted'
  s.license = 'MIT'

  s.rdoc_options = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']

  s.require_paths = ['lib']

  s.files      = Dir['lib/**/*.rb']
  s.test_files = Dir['test/**/*']

  s.required_ruby_version = '>= 2.7.0'

  s.add_dependency('encryptor', ['~> 3.0.0'])

  activerecord_version = "~> 7.0.8.7"
  s.add_development_dependency('activerecord', activerecord_version)
  s.add_development_dependency('actionpack', activerecord_version)
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('sequel')
  s.add_development_dependency('sqlite3')
  s.add_development_dependency('dm-sqlite-adapter')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('simplecov-rcov')
  s.add_development_dependency("codeclimate-test-reporter", '<= 0.6.0')

  s.post_install_message = "\n\n\nWARNING: Several insecure default options and features were deprecated in attr_encrypted v2.0.0.\n
Additionally, there was a bug in Encryptor v2.0.0 that insecurely encrypted data when using an AES-*-GCM algorithm.\n
This bug was fixed but introduced breaking changes between v2.x and v3.x.\n
Please see the README for more information regarding upgrading to attr_encrypted v3.0.0.\n\n\n"

end
