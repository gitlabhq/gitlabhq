RSpec::Matchers.define :have_header_with_correct_id_and_link do |level, text, id, parent = ".wiki"|
  match do |actual|
    node = find("#{parent} h#{level} a#user-content-#{id}")

    expect(node[:href]).to end_with("##{id}")

    # Work around a weird Capybara behavior where calling `parent` on a node
    # returns the whole document, not the node's actual parent element
    expect(find(:xpath, "#{node.path}/..").text).to eq(text)
  end
end
