# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gettext', :silence_stdout do
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
    before do
      allow(Rake::Task).to receive(:[]).and_call_original
    end

    it 'creates a pot file and invokes the \'gettext:po_to_json\' task' do
      expect(Rake::Task).to receive(:[]).with('gettext:po_to_json').and_return(double(invoke: true))

      expect { run_rake_task('gettext:compile') }
        .to change { File.exist?(pot_file_path) }
        .to be_truthy
    end
  end

  describe ':regenerate' do
    before do
      # this task takes a *really* long time to complete, so stub it for the spec
      allow(Rake::Task['gettext:find']).to receive(:invoke) { invoke_find.call }
    end

    context 'when the locale folder is not found' do
      let(:invoke_find) { -> { true } }

      before do
        FileUtils.rm_r(locale_path) if Dir.exist?(locale_path)
      end

      it 'raises an error' do
        expect { run_rake_task('gettext:regenerate') }
          .to raise_error(/Cannot find '#{locale_path}' folder/)
      end
    end

    context 'where there are existing /**/gitlab.po files' do
      let(:locale_nz_path) { File.join(locale_path, 'en_NZ') }
      let(:po_file_path) { File.join(locale_nz_path, 'gitlab.po') }

      let(:invoke_find) { -> { File.write pot_file_path, 'pot file test updates' } }

      before do
        FileUtils.mkdir(locale_nz_path)
        File.write(po_file_path, fixture_file('valid.po'))
      end

      it 'does not remove that locale' do
        expect { run_rake_task('gettext:regenerate') }
          .not_to change { Dir.exist?(locale_nz_path) }
      end
    end

    context 'when there are locale folders without a gitlab.po file' do
      let(:empty_locale_path) { File.join(locale_path, 'en_NZ') }

      let(:invoke_find) { -> { File.write pot_file_path, 'pot file test updates' } }

      before do
        FileUtils.mkdir(empty_locale_path)
      end

      it 'removes those folders' do
        expect { run_rake_task('gettext:regenerate') }
          .to change { Dir.exist?(empty_locale_path) }
          .to eq false
      end
    end

    context 'when the gitlab.pot file cannot be generated' do
      let(:invoke_find) { -> { true } }

      it 'prints an error' do
        expect { run_rake_task('gettext:regenerate') }
          .to raise_error(/gitlab.pot file not generated/)
      end
    end

    context 'when gettext:find changes the revision dates' do
      let(:invoke_find) { -> { File.write pot_file_path, fixture_file('valid.po') } }

      before do
        File.write pot_file_path, fixture_file('valid.po')
      end

      it 'resets the changes' do
        pot_file = File.read(pot_file_path)
        expect(pot_file).to include('PO-Revision-Date: 2017-07-13 12:10-0500')
        expect(pot_file).to include('PO-Creation-Date: 2016-07-13 12:11-0500')

        run_rake_task('gettext:regenerate')

        pot_file = File.read(pot_file_path)
        expect(pot_file).not_to include('PO-Revision-Date: 2017-07-13 12:10-0500')
        expect(pot_file).not_to include('PO-Creation-Date: 2016-07-13 12:11-0500')
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
