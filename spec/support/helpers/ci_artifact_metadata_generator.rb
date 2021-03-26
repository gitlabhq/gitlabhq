# frozen_string_literal: true

# frozen_sting_literal: true

# This generates fake CI metadata .gz for testing
# Based off https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/internal/zipartifacts/metadata.go
class CiArtifactMetadataGenerator
  attr_accessor :entries, :output

  ARTIFACT_METADATA = "GitLab Build Artifacts Metadata 0.0.2\n"

  def initialize(stream)
    @entries = {}
    @output = Zlib::GzipWriter.new(stream)
  end

  def add_entry(filename)
    @entries[filename] = { CRC: rand(0xfffffff), Comment: FFaker::Lorem.sentence(10) }
  end

  def write
    write_version
    write_errors
    write_entries
    output.close
  end

  private

  def write_version
    write_string(ARTIFACT_METADATA)
  end

  def write_errors
    write_string('{}')
  end

  def write_entries
    entries.each do |filename, metadata|
      write_string(filename)
      write_string(metadata.to_json + "\n")
    end
  end

  def write_string(data)
    bytes = [data.length].pack('L>')
    output.write(bytes)
    output.write(data)
  end
end
