Gem::Specification.new do |s|
  s.name          = 'gitlab-sidekiq-fetcher'
  s.version       = '0.12.0'
  s.authors       = ['TEA', 'GitLab']
  s.email         = 'valery@gitlab.com'
  s.license       = 'LGPL-3.0'
  s.homepage      = 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/sidekiq-reliable-fetch'
  s.summary       = 'Reliable fetch extension for Sidekiq'
  s.description   = 'Redis reliable queue pattern implemented in Sidekiq'
  s.require_paths = ['lib']
  s.files         = Dir.glob('lib/**/*.*')
  s.test_files    = Dir.glob('{spec,tests}/**/*.*')
  s.add_dependency 'sidekiq', '~> 7.0'
  s.add_runtime_dependency 'json', '>= 2.5'
end
