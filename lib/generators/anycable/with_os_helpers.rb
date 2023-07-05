# frozen_string_literal: true

module AnyCableRailsGenerators
  module WithOSHelpers
    OS_NAMES = %w[linux darwin freebsd win].freeze
    CPU_NAMES = %w[amd64 arm64 386 arm].freeze
    DEFAULT_BIN_PATH = "/usr/local/bin"

    def self.included(base)
      base.class_option :os,
        type: :string,
        desc: "Specify the OS for AnyCable-Go server binary (options: #{OS_NAMES.join(", ")})"
      base.class_option :cpu,
        type: :string,
        desc: "Specify the CPU architecturefor AnyCable-Go server binary (options: #{CPU_NAMES.join(", ")})"

      private :current_cpu, :supported_current_cpu, :supported_current_os
    end

    def current_cpu
      case Gem::Platform.local.cpu
      when "x86_64", "x64"
        "amd64"
      when "x86_32", "x86", "i386", "i486", "i686"
        "i386"
      when "aarch64", "aarch64_be", "arm64", /armv8/
        "arm64"
      when "arm", /armv7/, /armv6/
        "arm"
      else
        "unknown"
      end
    end

    def os_name
      options[:os] ||
        supported_current_os ||
        ask("What is your OS name?", limited_to: OS_NAMES)
    end

    def cpu_name
      options[:cpu] ||
        supported_current_cpu ||
        ask("What is your CPU architecture?", limited_to: CPU_NAMES)
    end

    def supported_current_cpu
      CPU_NAMES.find(&current_cpu.method(:==))
    end

    def supported_current_os
      OS_NAMES.find(&Gem::Platform.local.os.method(:==))
    end
  end
end
