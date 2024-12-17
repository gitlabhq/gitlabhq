# frozen_string_literal: true

RSpec.shared_examples 'issuables requiring filter' do |action, format: :html|
  it "doesn't load any issuables if no filter is set" do
    expect_any_instance_of(described_class).not_to receive(:issuables_collection)

    get action, format: format
  end

  it "loads issuables if at least one filter is set" do
    expect_any_instance_of(described_class).to receive(:issuables_collection).and_call_original

    get action, params: { author_id: user.id }, format: format
  end
end
