# frozen_string_literal: true

RSpec.shared_examples_for 'service deleting label links of an issuable' do
  let_it_be(:label_link) { create(:label_link, target: target) }

  def execute
    described_class.new(target.id, target.class.name).execute
  end

  it 'deletes label links for specified target ID and type' do
    control_count = ActiveRecord::QueryRecorder.new { execute }.count

    # Create more label links for the target
    create(:label_link, target: target)
    create(:label_link, target: target)

    expect { execute }.not_to exceed_query_limit(control_count)
    expect(target.reload.label_links.count).to eq(0)
  end
end
