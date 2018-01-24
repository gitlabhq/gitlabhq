shared_context 'with storage' do |store, **stub_params|
  before do
    subject.object_store = store
  end
end

shared_examples "migrates" do |to_store:, from_store: nil|
  let(:to) { to_store }
  let(:from) { from_store || subject.object_store }

  def migrate(to)
    subject.migrate!(to)
  end

  def checksum
    Digest::SHA256.hexdigest(subject.read)
  end

  before do
    migrate(from)
  end

  it 'does nothing when migrating to the current store' do
    expect { migrate(from) }.not_to change { subject.object_store }.from(from)
  end

  it 'migrate to the specified store' do
    from_checksum = checksum

    expect { migrate(to) }.to change { subject.object_store }.from(from).to(to)
    expect(checksum).to eq(from_checksum)
  end

  it 'removes the original file after the migration' do
    original_file = subject.file.path
    migrate(to)

    expect(File.exist?(original_file)).to be_falsey
  end

  context 'migration is unsuccessful' do
    shared_examples "handles gracefully" do |error:|
      it 'does not update the object_store' do
        expect { migrate(to) }.to raise_error(error)
        expect(subject.object_store).to eq(from)
      end

      it 'does not delete the original file' do
        expect { migrate(to) }.to raise_error(error)
        expect(subject.exists?).to be_truthy
      end
    end

    context 'when the store is not supported' do
      let(:to) { -1 } # not a valid store

      include_examples "handles gracefully", error: ObjectStorage::UnknownStoreError
    end

    context 'upon a fog failure' do
      before do
        storage_class = subject.send(:storage_for, to).class
        expect_any_instance_of(storage_class).to receive(:store!).and_raise("Store failure.")
      end

      include_examples "handles gracefully", error: "Store failure."
    end

    context 'upon a database failure' do
      before do
        expect(uploader).to receive(:persist_object_store!).and_raise("ActiveRecord failure.")
      end

      include_examples "handles gracefully", error: "ActiveRecord failure."
    end
  end
end

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
