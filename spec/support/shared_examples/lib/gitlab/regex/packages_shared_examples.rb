# frozen_string_literal: true

RSpec.shared_examples_for 'npm package name regex' do
  it { is_expected.to match('@scope/package') }
  it { is_expected.to match('unscoped-package') }
  it { is_expected.not_to match('@first-scope@second-scope/package') }
  it { is_expected.not_to match('scope-without-at-symbol/package') }
  it { is_expected.not_to match('@not-a-scoped-package') }
  it { is_expected.not_to match('@scope/sub/package') }
  it { is_expected.not_to match('@scope/../../package') }
  it { is_expected.not_to match('@scope%2e%2e%2fpackage') }
  it { is_expected.not_to match('@%2e%2e%2f/package') }
end
