# frozen_string_literal: true

RSpec.shared_examples 'regex rejecting path traversal' do
  it { is_expected.not_to match('a../b') }
  it { is_expected.not_to match('a..%2fb') }
  it { is_expected.not_to match('a%2e%2e%2fb') }
  it { is_expected.not_to match('a%2e%2e/b') }
end

RSpec.shared_examples 'container repository name regex' do
  it { is_expected.to match('image') }
  it { is_expected.to match('my/image') }
  it { is_expected.to match('my/awesome/image-1') }
  it { is_expected.to match('my/awesome/image.test') }
  it { is_expected.to match('my/awesome/image--test') }
  it { is_expected.to match('my/image__test') }

  # this example tests for catastrophic backtracking
  specify do
    string =
      'user1/project/a_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' \
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' \
        'bbbbbbbbbb------------x'
    is_expected.to match(string)
  end

  it { is_expected.not_to match('user1/project/a_bbbbb-------------') }
  it { is_expected.not_to match('my/image-.test') }
  it { is_expected.not_to match('my/image___test') }
  it { is_expected.not_to match('my/image_.test') }
  it { is_expected.not_to match('my/image_-test') }
  it { is_expected.not_to match('my/image..test') }
  it { is_expected.not_to match('my/image\ntest') }
  it { is_expected.not_to match('.my/image') }
  it { is_expected.not_to match('my/image.') }
end
