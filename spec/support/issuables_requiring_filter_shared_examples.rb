shared_examples 'issuables requiring filter' do |action|
  it "doesn't load any issuables if no filter is set" do
    expect_any_instance_of(described_class).not_to receive(:issuables_collection)

    get action

    expect(response).to render_template(action)
  end

  it "loads issuables if at least one filter is set" do
    expect_any_instance_of(described_class).to receive(:issuables_collection).and_call_original

    get action, author_id: user.id
  end
end
