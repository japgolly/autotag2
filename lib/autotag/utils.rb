# encoding: utf-8

module Autotag
  module Utils
    extend self

    def exec_with_console_title(title)
      old_title= nil
      on_exit= nil
      if get_os == :windows && libraries_available?('windows/console')
        old_title= "\0"*255
        Windows::Console::GetConsoleTitle.call(old_title, old_title.length-1)
        title16= title.encode('utf-16le')
        Windows::Console::SetConsoleTitle.call("#{title16}\0\0")
        on_exit= lambda{ Windows::Console::SetConsoleTitle.call(old_title) }
      end
      yield
    ensure
      on_exit.call if on_exit
    end

    def get_os
      case RUBY_PLATFORM
      when /mswin/  then :windows
      when /cygwin/ then :cygwin
      when /linux/  then :linix
      else :unknown
      end
    end

    def case_insensitive_filenames?
      get_os == :windows or get_os == :cygwin
    end
    def case_sensitive_filenames?
      !case_insensitive_filenames?
    end

    # Returns the charset for a system property
    def get_system_charset(type)
      if get_os == :windows and libraries_available?('windows/console','windows/national')
        cp= case type
          when :console        then Windows::Console::GetConsoleCP.call
          when :console_output then Windows::Console::GetConsoleOutputCP.call
          when :filenames      then Windows::National::GetACP.call
          else raise
          end
        if cp > 0
          enc= "CP#{cp}"
          enc= ICONV_CP_CONVERSIONS[enc] if ICONV_CP_CONVERSIONS[enc]
          return enc
        end
      end
      nil
    end

    # Load a library if it exists
    def libraries_available?(*names)
      names.each{|name|
        begin
          require name
        rescue LoadError
          return false
        end
      }
      true
    end

    private

    ICONV_CP_CONVERSIONS= {
      'CP936'   => 'GBK',
      'CP1361'  => 'JOHAB',
      'CP20127' => 'ASCII',
      'CP20866' => 'KOI8-R',
      'CP21866' => 'KOI8-RU',
      'CP28591' => 'ISO-8859-1',
      'CP28592' => 'ISO-8859-2',
      'CP28593' => 'ISO-8859-3',
      'CP28594' => 'ISO-8859-4',
      'CP28595' => 'ISO-8859-5',
      'CP28596' => 'ISO-8859-6',
      'CP28597' => 'ISO-8859-7',
      'CP28598' => 'ISO-8859-8',
      'CP28599' => 'ISO-8859-9',
      'CP28605' => 'ISO-8859-15',
      'CP65001' => 'UTF-8',
      }

    freeze_all_constants
  end
end
