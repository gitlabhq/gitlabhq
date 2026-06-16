# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:docs:compile_windows', :silence_stdout, feature_category: :pipeline_composition do
  let(:output_file) { 'doc/update/breaking_windows.md' }
  let(:deprecations_path) { 'data/deprecations' }

  before do
    Rake.application.rake_require 'tasks/gitlab/docs/compile_windows'
    # Load compile_deprecations for COLOR_CODE constants used by check_windows
    Rake.application.rake_require 'tasks/gitlab/docs/compile_deprecations'

    # Stub file system operations to avoid touching real files
    allow(Dir).to receive(:glob).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:open).and_call_original
  end

  after do
    # Reset WINDOWS state between tests
    WINDOWS.each_key do |key|
      WINDOWS[key][:changes] = []
    end
  end

  describe 'gitlab:docs:compile_windows' do
    let(:valid_deprecation) do
      {
        'title' => 'Test Breaking Change',
        'removal_milestone' => '19.0',
        'breaking_change' => true,
        'window' => 1,
        'impact' => 'high',
        'stage' => 'verify',
        'scope' => 'instance',
        'check_impact' => 'Check logs'
      }.to_yaml
    end

    it 'generates the markdown output file' do
      stub_deprecation_files({})

      expect(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

      run_rake_task('gitlab:docs:compile_windows')
    end

    it 'prints a success message' do
      stub_deprecation_files({})

      allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

      expect { run_rake_task('gitlab:docs:compile_windows') }
        .to output(/Breaking windows markdown file generated/).to_stdout
    end

    it 'writes metadata header to the output file' do
      stub_deprecation_files({})

      output = StringIO.new
      allow(File).to receive(:open).with(output_file, 'w').and_yield(output)

      run_rake_task('gitlab:docs:compile_windows')

      expect(output.string).to include('Breaking change deployments on GitLab.com')
    end

    context 'when processing deprecation files' do
      it 'processes a valid breaking change deprecation' do
        stub_deprecation_files({ 'test_dep.yml' => valid_deprecation })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        expect(WINDOWS[1][:changes].length).to eq(1)
        expect(WINDOWS[1][:changes].first[:title]).to eq('Test Breaking Change')
      end

      it 'excludes deprecations with a different removal_milestone' do
        deprecation = {
          'title' => 'Old Change',
          'removal_milestone' => '17.0',
          'breaking_change' => true,
          'window' => 1
        }.to_yaml

        stub_deprecation_files({ 'old_dep.yml' => deprecation })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        WINDOWS.each_value do |data|
          expect(data[:changes]).to be_empty
        end
      end

      it 'excludes non-breaking changes' do
        deprecation = {
          'title' => 'Non Breaking',
          'removal_milestone' => '19.0',
          'breaking_change' => false,
          'window' => 1
        }.to_yaml

        stub_deprecation_files({ 'non_breaking.yml' => deprecation })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        WINDOWS.each_value do |data|
          expect(data[:changes]).to be_empty
        end
      end

      it 'assigns non-window-2 deprecations to window 1' do
        deprecation = {
          'title' => 'No Specific Window',
          'removal_milestone' => '19.0',
          'breaking_change' => true,
          'window' => 99
        }.to_yaml

        stub_deprecation_files({ 'default_window.yml' => deprecation })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        expect(WINDOWS[1][:changes].length).to eq(1)
        expect(WINDOWS[2][:changes]).to be_empty
      end

      it 'handles a file containing an array of deprecations' do
        deprecations = [
          {
            'title' => 'Change One',
            'removal_milestone' => '19.0',
            'breaking_change' => true,
            'window' => 1
          },
          {
            'title' => 'Change Two',
            'removal_milestone' => '19.0',
            'breaking_change' => true,
            'window' => 2
          }
        ].to_yaml

        stub_deprecation_files({ 'multi.yml' => deprecations })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        expect(WINDOWS[1][:changes].length).to eq(1)
        expect(WINDOWS[2][:changes].length).to eq(1)
      end

      it 'handles a file containing a single deprecation (not an array)' do
        stub_deprecation_files({ 'single.yml' => valid_deprecation })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        expect(WINDOWS[1][:changes].length).to eq(1)
      end

      it 'assigns deprecations to both windows' do
        files = (1..2).to_h do |w|
          deprecation = {
            'title' => "Window #{w} Change",
            'removal_milestone' => '19.0',
            'breaking_change' => true,
            'window' => w
          }.to_yaml

          ["window_#{w}.yml", deprecation]
        end

        stub_deprecation_files(files)

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        WINDOWS.each_value do |data|
          expect(data[:changes].length).to eq(1)
        end
      end

      it 'excludes deprecations where gitlab_com is false' do
        deprecation = {
          'title' => 'Not for GitLab.com',
          'removal_milestone' => '19.0',
          'breaking_change' => true,
          'window' => 1,
          'gitlab_com' => false
        }.to_yaml

        stub_deprecation_files({ 'no_gitlab_com.yml' => deprecation })

        allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

        run_rake_task('gitlab:docs:compile_windows')

        WINDOWS.each_value do |data|
          expect(data[:changes]).to be_empty
        end
      end

      context 'when no deprecation files exist' do
        it 'generates the file with no changes in any window' do
          stub_deprecation_files({})

          allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

          run_rake_task('gitlab:docs:compile_windows')

          WINDOWS.each_value do |data|
            expect(data[:changes]).to be_empty
          end
        end
      end

      context 'when deprecation has nil values for optional fields' do
        it 'processes the deprecation without error' do
          deprecation = {
            'title' => 'Nil Fields Change',
            'removal_milestone' => '19.0',
            'breaking_change' => true,
            'window' => 1,
            'impact' => nil,
            'stage' => nil,
            'scope' => nil,
            'check_impact' => nil
          }.to_yaml

          stub_deprecation_files({ 'nil_fields.yml' => deprecation })

          allow(File).to receive(:open).with(output_file, 'w').and_yield(StringIO.new)

          run_rake_task('gitlab:docs:compile_windows')

          expect(WINDOWS[1][:changes].length).to eq(1)
        end
      end
    end
  end

  describe 'gitlab:docs:check_windows' do
    before do
      stub_deprecation_files({})
    end

    context 'when documentation is up to date' do
      it 'prints a success message' do
        # Generate the expected content
        expected_content = StringIO.new
        write_metadata(expected_content)
        write_windows_content(expected_content)

        allow(File).to receive(:read).with(output_file).and_return(expected_content.string)

        expect { run_rake_task('gitlab:docs:check_windows') }
          .to output(/Breaking windows documentation is up to date/).to_stdout
      end
    end

    context 'when documentation is outdated' do
      it 'prints an error and aborts' do
        allow(File).to receive(:read).with(output_file).and_return('outdated content')

        expect { run_rake_task('gitlab:docs:check_windows') }
          .to raise_error(SystemExit)
          .and output(/Breaking windows documentation is outdated/).to_stderr
      end
    end
  end

  def stub_deprecation_files(files)
    file_paths = files.map { |name, _content| File.join(deprecations_path, name) }
    allow(Dir).to receive(:glob).with("#{deprecations_path}/*.yml").and_return(file_paths)

    files.each do |name, content|
      path = File.join(deprecations_path, name)
      allow(File).to receive(:read).with(path).and_return(content)
    end
  end
end
