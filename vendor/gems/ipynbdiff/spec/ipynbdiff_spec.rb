# frozen_string_literal: true

require 'ipynbdiff'
require 'rspec'
require 'rspec-parameterized'

BASE_PATH = File.join(File.expand_path(File.dirname(__FILE__)),  'testdata')

describe IpynbDiff do
  def diff_signs(diff)
    diff.to_s(:text).scan(/.*\n/).map { |l| l[0] }.join('')
  end

  describe 'diff' do
    let(:from_path) { File.join(BASE_PATH, 'from.ipynb') }
    let(:to_path) { File.join(BASE_PATH,'to.ipynb') }
    let(:from) { File.read(from_path) }
    let(:to) { File.read(to_path) }
    let(:include_frontmatter) { false }
    let(:hide_images) { false }

    subject { IpynbDiff.diff(from, to, include_frontmatter: include_frontmatter, hide_images: hide_images) }

    context 'if preprocessing is active' do
      it 'html tables are stripped' do
        is_expected.to_not include('<td>')
      end
    end

    context 'when to is nil' do
      let(:to) { nil }
      let(:from_path) { File.join(BASE_PATH, 'only_md', 'input.ipynb') }

      it 'all lines are removals' do
        expect(diff_signs(subject)).to eq('-----')
      end
    end

    context 'when to is nil' do
      let(:from) { nil }
      let(:to_path) { File.join(BASE_PATH, 'only_md', 'input.ipynb') }

      it 'all lines are additions' do
        expect(diff_signs(subject)).to eq('+++++')
      end
    end

    context 'When include_frontmatter is true' do
      let(:include_frontmatter) { true }

      it 'should show changes metadata in the metadata' do
        expect(subject.to_s(:text)).to include('+    display_name: New Python 3 (ipykernel)')
      end
    end

    context 'When hide_images is true' do
      let(:hide_images) { true }

      it 'hides images' do
        expect(subject.to_s(:text)).to include('     [Hidden Image Output]')
      end
    end

    context 'When include_frontmatter is false' do
      it 'should drop metadata from the diff' do
        expect(subject.to_s(:text)).to_not include('+    display_name: New Python 3 (ipykernel)')
      end
    end

    context 'when either notebook can not be processed' do
      using RSpec::Parameterized::TableSyntax

      where(:ctx, :from, :to) do
        'because from is invalid'                 | 'a' | nil
        'because from does not have the cell tag' | '{"metadata":[]}' | nil
        'because to is invalid'                   | nil | 'a'
        'because to does not have the cell tag'   | nil | '{"metadata":[]}'
      end

      with_them do
        it { is_expected.to be_nil }
      end
    end
  end

  describe 'transform' do
    [nil, 'a', '{"metadata":[]}'].each do |invalid_nb|
      context "when json is invalid (#{invalid_nb || 'nil'})" do
        it 'is nil' do
          expect(IpynbDiff.transform(invalid_nb)).to be_nil
        end
      end
    end

    context 'options' do
      let(:include_frontmatter) { false }
      let(:hide_images) { false }

      subject do
        IpynbDiff.transform(File.read(File.join(BASE_PATH, 'from.ipynb')),
                            include_frontmatter: include_frontmatter,
                            hide_images: hide_images)
      end

      context 'include_frontmatter is false' do
        it { is_expected.to_not include('display_name: Python 3 (ipykernel)') }
      end

      context 'include_frontmatter is true' do
        let(:include_frontmatter) { true }

        it { is_expected.to include('display_name: Python 3 (ipykernel)') }
      end

      context 'hide_images is false' do
        it { is_expected.not_to include('[Hidden Image Output]') }
      end

      context 'hide_images is true' do
        let(:hide_images) { true }

        it { is_expected.to include('    [Hidden Image Output]') }
      end
    end
  end
end
