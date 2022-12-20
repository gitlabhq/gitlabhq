#!/usr/bin/env ruby
# https://docs.k0sproject.io/latest/k0s-in-docker/
# Runs in --prividged mode, only run this if you trust the k0s distribution.

require 'English'

# Like Kernel#system, returns true iff exit status == 0
def sh?(*cmd)
  puts("+ #{cmd.join(' ')}")
  system(*cmd)
end

# Raises if exit status != 0
def sh!(*cmd)
  sh?(*cmd) || raise("returned #{$CHILD_STATUS}")
end

# allow DOCKER='sudo docker', DOCKER=podman etc.
DOCKER = ENV['DOCKER'] || 'docker'

CONTAINER = 'k0s'.freeze

sh! "#{DOCKER} container inspect #{CONTAINER} --format='exists' ||
  #{DOCKER} run -d --name #{CONTAINER} --hostname k0s --privileged -v /var/lib/k0s -p 6443:6443 \
  ghcr.io/k0sproject/k0s/k0s:v1.23.3-k0s.1"

# sh! "#{DOCKER} exec #{CONTAINER} kubectl config view --raw"
# is another way to dump kubeconfig but succeeds with dummy output even before admin.conf exists;
# so accessing the file is better way as it lets us poll until ready:
sleep(1) until sh?("#{DOCKER} exec #{CONTAINER} ls -l /var/lib/k0s/pki/admin.conf")

sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/admin.conf > test/config/allinone.kubeconfig"
# The rest could easily be extracted from allinone.kubeconfig, but the test is more robust
# if we don't reuse YAML and/or Kubeclient::Config parsing to construct test data.
sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/ca.crt     > test/config/external-ca.pem"
sh! 'cat test/config/another-ca1.pem test/config/external-ca.pem '\
    '    test/config/another-ca2.pem > test/config/concatenated-ca.pem'
sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/admin.crt  > test/config/external-cert.pem"
sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/admin.key  > test/config/external-key.rsa"

# Wait for apiserver to be up.  To speed startup, this only retries connection errors;
# without `--fail-with-body` curl still returns 0 for well-formed 4xx or 5xx responses.
sleep(1) until sh?(
  'curl --cacert test/config/external-ca.pem ' \
  '--key test/config/external-key.rsa ' \
  '--cert test/config/external-cert.pem  https://127.0.0.1:6443/healthz'
)

sh! 'env KUBECLIENT_TEST_REAL_CLUSTER=true bundle exec rake test'

sh! "#{DOCKER} rm -f #{CONTAINER}"

puts 'If you run this only for tests, cleanup by running: git restore test/config/'
