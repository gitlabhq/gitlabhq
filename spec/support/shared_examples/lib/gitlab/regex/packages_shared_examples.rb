# frozen_string_literal: true

RSpec.shared_examples_for 'package name regex' do
  it { is_expected.to match('123') }
  it { is_expected.to match('foo') }
  it { is_expected.to match('foo/bar') }
  it { is_expected.to match('@foo/bar') }
  it { is_expected.to match('com/mycompany/app/my-app') }
  it { is_expected.to match('my-package/1.0.0@my+project+path/beta') }
  it { is_expected.not_to match('my-package/1.0.0@@@@@my+project+path/beta') }
  it { is_expected.not_to match('$foo/bar') }
  it { is_expected.not_to match('@foo/@/bar') }
  it { is_expected.not_to match('@@foo/bar') }
  it { is_expected.not_to match('my package name') }
  it { is_expected.not_to match('!!()()') }
  it { is_expected.not_to match("..\n..\foo") }

  it 'has no backtracking issue' do
    Timeout.timeout(1) do
      expect(subject).not_to match("#{'-' * 50000};")
    end
  end
end

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
