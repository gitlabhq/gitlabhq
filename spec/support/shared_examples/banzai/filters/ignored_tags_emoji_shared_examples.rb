# frozen_string_literal: true

RSpec.shared_examples 'ignored ancestor tags' do
  it 'does not match emoji in a pre tag' do
    doc = filter("<p><pre>#{emoji_name}</pre></p>")

    expect(doc.css('img').size).to eq 0
  end

  it 'does not match emoji in code tag' do
    doc = filter("<p><code>#{emoji_name} wow</code></p>")

    expect(doc.css('img').size).to eq 0
  end

  it 'does not match emoji in tt tag' do
    doc = filter("<p><tt>#{emoji_name} yes!</tt></p>")

    expect(doc.css('img').size).to eq 0
  end
end
