# frozen_string_literal: true

require 'zlib'
require 'stackprof'

module CloudProfilerAgent
  # PprofBuilder converts from stackprof to pprof formats.
  #
  # Typical usage:
  #
  #   start_time = Time.now
  #   stackprof = StackProf.run(mode: :cpu, raw: true) do
  #     # ...
  #   end
  #   pprof = PprofBuilder.convert_stackprof(stackprof, start_time, Time.now)
  #   IO::binwrite('profile.pprof', pprof)
  #
  # StackProf must be invoked with raw: true for the conversion to work.
  #
  # The pprof format is a gzip-compressed protobuf, documented here:
  # https://github.com/google/pprof/blob/master/proto/profile.proto
  #
  # The conversion is not quite isomorphic. In particular, each sample in pprof
  # consists of a stack with line numbers and even instruction addresses.
  # StackProf on the other hand records stack frames with only function-level
  # granularity. Thus, the line numbers in the pprof output only reflect the
  # first line of the function, regardless of which line was actually in the
  # stack frame.
  class PprofBuilder
    def self.convert_stackprof(stackprof, start_time, end_time)
      converter = PprofBuilder.new(stackprof, start_time, end_time)
      converter.pprof_bytes
    end

    def initialize(profile, start_time, end_time)
      @profile = profile
      @start_time = start_time
      @duration = end_time - start_time

      @string_map = StringMap.new
    end

    # message returns a Perftools::Profiles::Profile, the deserialized version
    # of a pprof profile.
    def message
      main_mapping = Perftools::Profiles::Mapping.new(
        id: 1,
        filename: @string_map.add('TODO')
      )

      message = Perftools::Profiles::Profile.new(
        sample_type: [sample_type],
        mapping: [main_mapping],
        time_nanos: @start_time.to_i * 1_000_000_000,
        duration_nanos: @duration * 1_000_000_000,
        period_type: sample_type,
        period: period,
        default_sample_type: 0
      )
      process_raw(message)
      process_frames(message)
      message.string_table += @string_map.strings
      message
    end

    # pprof_bytes returns a gzip'd protobuf object, like would be written to
    # disk, returned by a profiling endpoint, or otherwise consumed by the
    # `pprof` tool.
    def pprof_bytes
      Zlib.gzip(Perftools::Profiles::Profile.encode(message))
    end

    private

    def to_pprof_unit(value)
      case @profile.fetch(:mode)
      when :cpu, :wall
        value * 1000 # stackprof uses microseconds, pprof nanoseconds
      when :object
        value # both stackprof and pprof are counting allocations
      else
        raise "unknown profile mode #{@profile.fetch(:mode)}"
      end
    end

    def period
      to_pprof_unit @profile.fetch(:interval)
    end

    def sample_type
      case @profile.fetch(:mode)
      when :cpu
        type = 'cpu'
        unit = 'nanoseconds'
      when :wall
        type = 'wall'
        unit = 'nanoseconds'
      when :object
        type = 'alloc_objects'
        unit = 'count'
      else
        raise "unknown profile mode #{@profile.fetch(:mode)}"
      end

      Perftools::Profiles::ValueType.new(
        type: @string_map.add(type),
        unit: @string_map.add(unit)
      )
    end

    # process_raw reads the :raw section of the stackprof profile and adds to
    # the given protobuf message as appropriate
    def process_raw(message)
      i = 0
      raw = @profile.fetch(:raw, [])

      # It would be cleaner to use raw.shift here, but since that changes the
      # size of the array each time it is much slower. So we use an
      # incrementing pointer instead.
      while i < raw.length
        len = raw.fetch(i)
        i += 1

        frames = raw.slice(i, len)
        i += len
        frames.reverse!

        # "weight" is how many times stackprof has seen this stack. It's
        # usually 1, but can be 2 or more if stackprof sees the same stack in
        # sequential samples.
        weight = raw.fetch(i)
        i += 1

        sample = Perftools::Profiles::Sample.new(
          value: [weight * period],
          location_id: frames
        )
        message.sample.push(sample)
      end
    end

    # process_frames reads the :frames section of the stackprof profile and adds to
    # the given protobuf message as appropriate
    def process_frames(message)
      @profile.fetch(:frames, []).each do |location_id, location|
        message.function.push(Perftools::Profiles::Function.new(
          id: location_id,
          name: @string_map.add(location.fetch(:name)),
          filename: @string_map.add(location.fetch(:file)),
          start_line: location.fetch(:line, nil)
        ))

        line = Perftools::Profiles::Line.new(
          function_id: location_id,
          line: location.fetch(:line, nil)
        )

        message.location.push(Perftools::Profiles::Location.new(
          id: location_id,
          line: [line]
        ))
      end
    end
  end

  # The pprof format has one table of strings, and objects that need strings
  # (like filenames, function names, etc) are indexes into this table,
  # achieving a cheap kind of compression for commonly repeated strings.
  # StringMap is a helper for building this table.
  class StringMap
    def initialize
      @strings = []
      @string_hash = {}
      add('') # spec says string_table[0] must always be "".
    end

    # strings an array of all the strings which will go into the pprof message.
    attr_reader :strings

    # add will return an index for the given string, either returning the
    # existing index or adding a new string to the table as appropriate.
    def add(str)
      i = @string_hash.fetch(str, nil)
      return i unless i.nil?

      i = strings.push(str).length - 1
      @string_hash[str] = i
      i
    end
  end
end
