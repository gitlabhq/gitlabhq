# frozen_string_literal: true

module FixtureHelpers
  def fixture_file(filename, dir: '')
    return '' if filename.blank?

    File.read(expand_fixture_path(filename, dir: dir))
  end

  def expand_fixture_path(filename, dir: '')
    File.expand_path(rails_root_join(dir, 'spec', 'fixtures', filename))
  end

  def ci_artifact_fixture_size(filename = 'ci_build_artifacts.zip')
    File::Stat.new(expand_fixture_path(filename)).size
  end
end
