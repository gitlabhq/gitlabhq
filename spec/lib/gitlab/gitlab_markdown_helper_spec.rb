require 'spec_helper'

describe Gitlab::MarkdownHelper do
  describe '#markup?' do
    %w(textile rdoc org creole wiki
       mediawiki rst adoc asciidoc asc).each do |type|
      it "returns true for #{type} files" do
        expect(Gitlab::MarkdownHelper.markup?("README.#{type}")).to be_truthy
      end
    end

    it 'returns false when given a non-markup filename' do
      expect(Gitlab::MarkdownHelper.markup?('README.rb')).not_to be_truthy
    end
  end

  describe '#gitlab_markdown?' do
    %w(mdown md markdown).each do |type|
      it "returns true for #{type} files" do
        expect(Gitlab::MarkdownHelper.gitlab_markdown?("README.#{type}")).to be_truthy
      end
    end

    it 'returns false when given a non-markdown filename' do
      expect(Gitlab::MarkdownHelper.gitlab_markdown?('README.rb')).not_to be_truthy
    end
  end
end
