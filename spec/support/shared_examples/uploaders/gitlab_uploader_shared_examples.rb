shared_examples "matches the method pattern" do |method|
  let(:target) { subject }
  let(:args) { nil }
  let(:pattern) { patterns[method] }

  it do
    return skip "No pattern provided, skipping." unless pattern

    expect(target.method(method).call(*args)).to match(pattern)
  end
end

shared_examples "builds correct paths" do |**patterns|
  let(:patterns) { patterns }

  before do
    allow(subject).to receive(:filename).and_return('<filename>')
  end

  describe "#store_dir" do
    it_behaves_like "matches the method pattern", :store_dir
  end

  describe "#cache_dir" do
    it_behaves_like "matches the method pattern", :cache_dir
  end

  describe "#work_dir" do
    it_behaves_like "matches the method pattern", :work_dir
  end

  describe "#upload_path" do
    it_behaves_like "matches the method pattern", :upload_path
  end

  describe ".absolute_path" do
    it_behaves_like "matches the method pattern", :absolute_path do
      let(:target) { subject.class }
      let(:args) { [upload] }
    end
  end

  describe ".base_dir" do
    it_behaves_like "matches the method pattern", :base_dir do
      let(:target) { subject.class }
    end
  end
end
