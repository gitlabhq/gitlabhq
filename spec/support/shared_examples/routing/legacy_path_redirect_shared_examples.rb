# frozen_string_literal: true

RSpec.shared_examples 'redirecting a legacy project path' do |source, target|
  include RSpec::Rails::RequestExampleGroup

  it "redirects #{source} to #{target}" do
    expect(get(source)).to redirect_to(target)
  end
end
