require 'spec_helper'

describe Gitlab::MarkupHelper, lib: true do
  describe '#markup?' do
    %w(textile rdoc org creole wiki
       mediawiki rst adoc ad asciidoc mdown md markdown).each do |type|
      it "returns true for #{type} files" do
        expect(Gitlab::MarkupHelper.markup?("README.#{type}")).to be_truthy
      end
    end

    it 'returns false when given a non-markup filename' do
      expect(Gitlab::MarkupHelper.markup?('README.rb')).not_to be_truthy
    end
  end

  describe '#gitlab_markdown?' do
    %w(mdown mkd mkdn md markdown).each do |type|
      it "returns true for #{type} files" do
        expect(Gitlab::MarkupHelper.gitlab_markdown?("README.#{type}")).to be_truthy
      end
    end

    it 'returns false when given a non-markdown filename' do
      expect(Gitlab::MarkupHelper.gitlab_markdown?('README.rb')).not_to be_truthy
    end
  end

  describe '#asciidoc?' do
    %w(adoc ad asciidoc ADOC).each do |type|
      it "returns true for #{type} files" do
        expect(Gitlab::MarkupHelper.asciidoc?("README.#{type}")).to be_truthy
      end
    end

    it 'returns false when given a non-asciidoc filename' do
      expect(Gitlab::MarkupHelper.asciidoc?('README.rb')).not_to be_truthy
    end
  end
end
