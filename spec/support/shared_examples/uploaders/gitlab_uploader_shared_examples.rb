# frozen_string_literal: true

RSpec.shared_examples "matches the method pattern" do |method|
  let(:target) { subject }
  let(:args) { nil }
  let(:pattern) { patterns[method] }

  it do
    skip "No pattern provided, skipping." unless pattern

    expect(target.method(method).call(*args)).to match(pattern)
  end
end

RSpec.shared_examples "builds correct paths" do |**patterns|
  let(:patterns) { patterns }
  let(:fixture) { File.join('spec', 'fixtures', 'rails_sample.jpg') }

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

  describe "#relative_path" do
    it 'is relative' do
      skip 'Path not set, skipping.' unless subject.path

      expect(Pathname.new(subject.relative_path)).to be_relative
    end
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

  describe "path traversal exploits" do
    before do
      allow(subject).to receive(:filename).and_return("3bc58d54542d6a5efffa9a87554faac0254f73f675b337899ea869f6d38b7371/122../../../../../../../../.ssh/authorized_keys")
    end

    it "throws an exception" do
      expect { subject.cache!(fixture_file_upload(fixture)) }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
      expect { subject.store!(fixture_file_upload(fixture)) }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
    end
  end
end
