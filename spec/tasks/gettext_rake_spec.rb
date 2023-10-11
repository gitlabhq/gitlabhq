# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tooling/lib/tooling/gettext_extractor'
require_relative '../support/matchers/abort_matcher'

RSpec.describe 'gettext', :silence_stdout, feature_category: :internationalization do
  let(:locale_path) { Rails.root.join('tmp/gettext_spec') }
  let(:pot_file_path) { File.join(locale_path, 'gitlab.pot') }

  before do
    Rake.application.rake_require('tasks/gettext')

    FileUtils.rm_r(locale_path) if Dir.exist?(locale_path)
    FileUtils.mkdir_p(locale_path)

    allow(Rails.root).to receive(:join).and_call_original
    allow(Rails.root).to receive(:join).with('locale').and_return(locale_path)
  end

  after do
    FileUtils.rm_r(locale_path) if Dir.exist?(locale_path)
  end

  describe ':compile' do
    let(:compile_command) do
      [
        "node", "./scripts/frontend/po_to_json.js",
        "--locale-root", Rails.root.join('locale').to_s,
        "--output-dir", Rails.root.join('app/assets/javascripts/locale').to_s
      ]
    end

    it 'creates a pot file and runs po-to-json conversion via node script' do
      expect(Kernel).to receive(:system).with(*compile_command).and_return(true)

      expect { run_rake_task('gettext:compile') }
        .to change { File.exist?(pot_file_path) }
        .to be_truthy
    end

    it 'aborts with non-successful po-to-json conversion via node script' do
      expect(Kernel).to receive(:system).with(*compile_command).and_return(false)

      expect { run_rake_task('gettext:compile') }.to abort_execution
    end
  end

  describe ':regenerate' do
    let(:locale_nz_path) { File.join(locale_path, 'en_NZ') }
    let(:po_file_path) { File.join(locale_nz_path, 'gitlab.po') }
    let(:extractor) { instance_double(Tooling::GettextExtractor, generate_pot: '') }

    before do
      FileUtils.mkdir(locale_nz_path)
      File.write(po_file_path, fixture_file('valid.po'))

      # this task takes a *really* long time to complete, so stub it for the spec
      allow(Tooling::GettextExtractor).to receive(:new).and_return(extractor)
    end

    context 'when the locale folder is not found' do
      before do
        FileUtils.rm_r(locale_path) if Dir.exist?(locale_path)
      end

      it 'raises an error' do
        expect { run_rake_task('gettext:regenerate') }
          .to raise_error(/Cannot find '#{locale_path}' folder/)
      end
    end

    context 'when the gitlab.pot file cannot be generated' do
      it 'prints an error' do
        allow(File).to receive(:exist?).and_return(false)

        expect { run_rake_task('gettext:regenerate') }
          .to raise_error(/gitlab.pot file not generated/)
      end
    end
  end

  describe ':lint' do
    before do
      # make sure we test on the fixture files, not the actual gitlab repo as
      # this takes a long time
      allow(Rails.root)
        .to receive(:join)
        .with('locale/*/gitlab.po')
        .and_return(File.join(locale_path, '*/gitlab.po'))
    end

    context 'when all PO files are valid' do
      before do
        nz_locale_path = File.join(locale_path, 'en_NZ')
        FileUtils.mkdir(nz_locale_path)

        po_file_path = File.join(nz_locale_path, 'gitlab.po')
        File.write(po_file_path, fixture_file('valid.po'))
        File.write(pot_file_path, fixture_file('valid.po'))
      end

      it 'completes without error' do
        expect { run_rake_task('gettext:lint') }
          .not_to raise_error
      end
    end

    context 'when there are invalid PO files' do
      before do
        nz_locale_path = File.join(locale_path, 'en_NZ')
        FileUtils.mkdir(nz_locale_path)

        po_file_path = File.join(nz_locale_path, 'gitlab.po')
        File.write(po_file_path, fixture_file('invalid.po'))
        File.write(pot_file_path, fixture_file('valid.po'))
      end

      it 'raises an error' do
        expect { run_rake_task('gettext:lint') }
          .to raise_error(/Not all PO-files are valid/)
      end
    end

    context 'when the .pot file is invalid' do
      before do
        nz_locale_path = File.join(locale_path, 'en_NZ')
        FileUtils.mkdir(nz_locale_path)

        po_file_path = File.join(nz_locale_path, 'gitlab.po')
        File.write(po_file_path, fixture_file('valid.po'))
        File.write(pot_file_path, fixture_file('invalid.po'))
      end

      it 'raises an error' do
        expect { run_rake_task('gettext:lint') }
          .to raise_error(/Not all PO-files are valid/)
      end
    end
  end
end
