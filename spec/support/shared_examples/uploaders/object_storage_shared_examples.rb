shared_context 'with storage' do |store, **stub_params|
  before do
    subject.object_store = store
  end
end

shared_examples "builds correct paths" do |**patterns|
  before do
    allow(subject).to receive(:filename).and_return('<filename>')
  end

  describe "#store_dir" do
    it "matches the pattern" do
      expect(subject.store_dir).to match(patterns[:store_dir])
    end
  end if patterns.has_key?(:store_dir)

  describe "#cache_dir" do
    it "matches the pattern" do
      expect(subject.cache_dir).to match(patterns[:cache_dir])
    end
  end if patterns.has_key?(:cache_dir)

  describe "#work_dir" do
    it "matches the pattern" do
      expect(subject.work_dir).to match(patterns[:work_dir])
    end
  end if patterns.has_key?(:work_dir)

  describe "#upload_path" do
    it "matches the pattern" do
      expect(subject.upload_path).to match(patterns[:upload_path])
    end
  end if patterns.has_key?(:upload_path)

  describe ".absolute_path" do
    it "matches the pattern" do
      expect(subject.class.absolute_path(upload)).to match(patterns[:absolute_path])
    end
  end if patterns.has_key?(:absolute_path)

  describe ".base_dir" do
    it "matches the pattern" do
      expect(subject.class.base_dir).to match(patterns[:base_dir])
    end
  end if patterns.has_key?(:base_dir)
end
