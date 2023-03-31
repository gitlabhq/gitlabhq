# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::Finders::GlobalTemplateFinder do
  let(:base_dir) { Dir.mktmpdir }

  def create_template!(name_with_category)
    full_path = File.join(base_dir, name_with_category)
    FileUtils.mkdir_p(File.dirname(full_path))
    FileUtils.touch(full_path)
  end

  after do
    FileUtils.rm_rf(base_dir)
  end

  subject(:finder) do
    described_class.new(
      base_dir, '',
      { 'General' => '', 'Bar' => 'Bar' },
      include_categories_for_file,
      excluded_patterns: excluded_patterns
    )
  end

  let(:excluded_patterns) { [] }
  let(:include_categories_for_file) do
    {
      "SAST" => { "Security" => "Security" }
    }
  end

  describe '.find' do
    context 'with a non-prefixed General template' do
      before do
        create_template!('test-template')
      end

      it 'finds the template with no prefix' do
        expect(finder.find('test-template')).to be_present
      end

      it 'does not find a prefixed template' do
        expect(finder.find('Bar/test-template')).to be_nil
      end

      it 'does not permit path traversal requests' do
        expect { finder.find('../foo') }.to raise_error(/Invalid path/)
      end

      context 'while listed as an exclusion' do
        let(:excluded_patterns) { [%r{^test-template$}] }

        it 'does not find the template without a prefix' do
          expect(finder.find('test-template')).to be_nil
        end

        it 'does not find the template with a prefix' do
          expect(finder.find('Bar/test-template')).to be_nil
        end

        it 'finds another prefixed template with the same name' do
          create_template!('Bar/test-template')

          expect(finder.find('test-template')).to be_nil
          expect(finder.find('Bar/test-template')).to be_present
        end
      end
    end

    context 'with a prefixed template' do
      before do
        create_template!('Bar/test-template')
        create_template!('Security/SAST')
      end

      it 'finds the template with a prefix' do
        expect(finder.find('Bar/test-template')).to be_present
      end

      # NOTE: This spec fails, the template Bar/test-template is found
      # See Gitlab issue: https://gitlab.com/gitlab-org/gitlab/issues/205719
      xit 'does not find the template without a prefix' do
        expect(finder.find('test-template')).to be_nil
      end

      it 'does not permit path traversal requests' do
        expect { finder.find('../foo') }.to raise_error(/Invalid path/)
      end

      context 'with include_categories_for_file being present' do
        it 'finds the template with a prefix' do
          expect(finder.find('SAST')).to be_present
        end

        it 'does not find any template which is missing in include_categories_for_file' do
          expect(finder.find('DAST')).to be_nil
        end
      end

      context 'while listed as an exclusion' do
        let(:excluded_patterns) { [%r{^Bar/test-template$}] }

        it 'does not find the template with a prefix' do
          expect(finder.find('Bar/test-template')).to be_nil
        end

        # NOTE: This spec fails, the template Bar/test-template is found
        # See Gitlab issue: https://gitlab.com/gitlab-org/gitlab/issues/205719
        xit 'does not find the template without a prefix' do
          expect(finder.find('test-template')).to be_nil
        end

        it 'finds another non-prefixed template with the same name' do
          create_template!('Bar/test-template')

          expect(finder.find('test-template')).to be_present
          expect(finder.find('Bar/test-template')).to be_nil
        end
      end

      context 'while listed as an exclusion' do
        let(:excluded_patterns) { [%r{\.latest$}] }

        it 'excludes the template matched the pattern' do
          create_template!('test-template.latest')

          expect(finder.find('test-template')).to be_present
          expect(finder.find('test-template.latest')).to be_nil
        end
      end
    end
  end
end
