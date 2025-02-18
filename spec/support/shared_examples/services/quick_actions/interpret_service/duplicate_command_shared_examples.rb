# frozen_string_literal: true

RSpec.shared_examples 'duplicate command' do
  it 'fetches issue and populates canonical_issue_id if content contains /duplicate issue_reference' do
    duplicate_item # populate the issue
    _, updates, _ = service.execute(content, issuable)

    expect(updates).to eq(canonical_issue_id: duplicate_item.id)
  end

  it 'returns the duplicate message' do
    _, _, message = service.execute(content, issuable)
    translated_string = _("Closed this %{work_item_type}. Marked as related to, and a duplicate of, %{work_item_url}.")
    formatted_message = format(
      translated_string,
      work_item_type: issuable.work_item_type.name,
      work_item_url: Gitlab::UrlBuilder.build(duplicate_item)
    )

    expect(message).to eq(formatted_message)
  end

  it 'includes duplicate reference' do
    _, explanations = service.explain(content, issuable)
    translated_string = _("Closes this %{work_item_type}. Marks as related to, and a duplicate of, %{work_item_url}.")
    formatted_message = format(
      translated_string,
      work_item_type: issuable.work_item_type.name,
      work_item_url: Gitlab::UrlBuilder.build(duplicate_item)
    )

    expect(explanations).to eq([formatted_message])
  end
end
