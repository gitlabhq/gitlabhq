require 'spec_helper'

describe TreeHelper do
  describe '#markup?' do
    %w(textile rdoc org creole mediawiki rst asciidoc pod).each do |type|
      it "returns true for #{type} files" do
        expect(markup?("README.#{type}")).to be_true
      end
    end

    it "returns false when given a non-markup filename" do
      expect(markup?('README.rb')).not_to be_true
    end
  end
end
