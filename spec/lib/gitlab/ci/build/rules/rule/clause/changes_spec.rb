# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Changes do
  describe '#satisfied_by?' do
    it_behaves_like 'a glob matching rule' do
      let(:pipeline) { build(:ci_pipeline) }

      before do
        allow(pipeline).to receive(:modified_paths).and_return(files.keys)
      end

      subject { described_class.new(globs).satisfied_by?(pipeline, nil) }
    end
  end
end
