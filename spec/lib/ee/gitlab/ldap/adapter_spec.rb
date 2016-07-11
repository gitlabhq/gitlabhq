require 'spec_helper'

# Test things specific to the EE mixin, but run the actual tests
# against the main adapter class to ensure it's properly included
describe Gitlab::LDAP::Adapter, lib: true do
  subject { Gitlab::LDAP::Adapter.new 'ldapmain' }

  it { is_expected.to include_module(EE::Gitlab::LDAP::Adapter) }
end
