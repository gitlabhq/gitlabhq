# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Slug::Path, feature_category: :shared do
  describe '#generate' do
    {
      name: 'name',
      'james.atom@bond.com': 'james',
      '--foobar--': 'foobar--',
      '--foo_bar--': 'foo_bar--',
      '--foo$^&_bar--': 'foo_bar--',
      'john@doe.com': 'john',
      '-john+gitlab-ETC%.git@gmail.com': 'johngitlab-ETC',
      'this.is.git.atom.': 'this.is',
      '#$%^.': 'blank',
      '---.git#$.atom%@atom^.': 'blank', # use default when all characters are filtered out
      '--gitlab--hey.git#$.atom%@atom^.': 'gitlab--hey'
    }.each do |input, output|
      it "yields a slug #{output} when given #{input}" do
        slug = described_class.new(input).generate

        expect(slug).to match(/\A#{output}\z/)
      end
    end
  end

  describe '#to_s' do
    it 'presents with a cleaned slug' do
      expect(described_class.new('---show-me-what-you.got.git').to_s).to match(/\Ashow-me-what-you.got\z/)
    end
  end
end
