describe Gitlab::Diff::Line do
  describe '.init_from_hash' do
    it 'round-trips correctly with to_hash' do
      line = described_class.new('<input>', 'match', 0, 0, 1,
                                 parent_file: double(:file),
                                 line_code: double(:line_code),
                                 rich_text: '&lt;input&gt;')

      expect(described_class.init_from_hash(line.to_hash).to_hash)
        .to eq(line.to_hash)
    end
  end

  context "when setting rich text" do
    it 'escapes any HTML special characters in the diff chunk header' do
      subject = described_class.new("<input>", "", 0, 0, 0)
      line = subject.as_json

      expect(line[:rich_text]).to eq("&lt;input&gt;")
    end
  end
end
