shared_examples 'redirecting a legacy path' do |source, target|
  include RSpec::Rails::RequestExampleGroup

  it "redirects #{source} to #{target} when the resource does not exist" do
    expect(get(source)).to redirect_to(target)
  end

  it "does not redirect #{source} to #{target} when the resource exists" do
    resource

    expect(get(source)).not_to redirect_to(target)
  end
end
