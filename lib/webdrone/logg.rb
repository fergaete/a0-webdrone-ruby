module Webdrone
  class MethodLogger < Module
    def initialize(methods_0 = nil)
      @methods_0 = methods_0
    end

    def included(base)
      @methods_0 = base.instance_methods(false) if @methods_0 == nil
      method_list = @methods_0
      base.class_eval do
        method_list.each do |method_name|
          original_method = instance_method(method_name)
          define_method method_name do |*args, &block|
            caller_location = Kernel.caller_locations[0]
            cl_path = caller_location.path
            cl_line = caller_location.lineno
            if @a0.conf.logger and Gem.path.none? { |path| cl_path.include? path }
              $a0_webdrone_logger_last_time = Time.new unless $a0_webdrone_logger_last_time
              ini = $a0_webdrone_logger_last_time
              $a0_webdrone_screenshot = nil
              begin
                result = original_method.bind(self).call(*args, &block)
                fin = $a0_webdrone_logger_last_time = Time.new
                @a0.logs.trace(ini, fin, cl_path, cl_line, base, method_name, args, result, nil, $a0_webdrone_screenshot)
                result
              rescue => exception
                fin = $a0_webdrone_logger_last_time = Time.new
                @a0.logs.trace(ini, fin, cl_path, cl_line, base, method_name, args, nil, exception, $a0_webdrone_screenshot)
                raise exception
              end
            else
              original_method.bind(self).call(*args, &block)
            end
          end
        end
      end
    end
  end

  class Browser
    def logs
      @logs ||= Logs.new self
    end
  end

  class Logs
    attr_accessor :a0

    def initialize(a0)
      @a0 = a0
      @group_trace_count = []
      setup_format
      setup_trace
    end

    def trace(ini, fin, from, lineno, base, method_name, args, result, exception, screenshot)
      exception = "#{exception.class}: #{exception}" if exception
      printf @format, (fin-ini), base, method_name, args, (result || exception)
      CSV.open(@path, "a+") do |csv|
        csv << [ini.strftime('%Y-%m-%d %H:%M:%S.%L %z'), (fin-ini), from, lineno, base, method_name, args, result, exception, screenshot]
      end
      @group_trace_count = @group_trace_count.map { |x| x + 1 }
    end

    def with_group(name, abort_error: false)
      ini = Time.new
      caller_location = Kernel.caller_locations[0]
      cl_path = caller_location.path
      cl_line = caller_location.lineno
      result = {}
      @group_trace_count << 0
      exception = nil
      begin
        yield
      rescue => e
        exception = e
        bindings = Kernel.binding.callers
        bindings[0..-1].each_with_index do |binding, index|
          location = { path: binding.eval('__FILE__'), lineno: binding.eval('__LINE__') }
          if Gem.path.none? { |path| location[:path].include? path }
            result[:exception] = {}
            result[:exception][:line] = location[:lineno]
            result[:exception][:path] = location[:path]
            break
          end
        end        
      end
      result[:trace_count] = @group_trace_count.pop
      fin = Time.new
      trace(ini, fin, cl_path, cl_line, Logs, :with_group, [name, abort_error: abort_error], result, exception, nil)
      puts "abort_error: #{abort_error} exception: #{exception}"
      exit if abort_error == true and exception
    end

    def setup_format
      cols, line = HighLine::SystemExtensions.terminal_size
      total = 6 + 15 + 11 + 5
      w = cols - total
      w /= 2
      w1 = w
      w2 = cols - total - w1
      w1 = 20 if w1 < 20
      w2 = 20 if w2 < 20
      @format = "%5.3f %14.14s %10s %#{w1}.#{w1}s => %#{w2}.#{w2}s\n"
    end

    def setup_trace
      @path = File.join(a0.conf.outdir, 'a0_webdrone_trace.csv')
      CSV.open(@path, "a+") do |csv|
        os = "Windows" if OS.windows?
        os = "Linux" if OS.linux?
        os = "OS X" if OS.osx?
        bits = OS.bits
        hostname = Socket.gethostname
        browser_name = a0.driver.capabilities[:browser_name]
        browser_version = a0.driver.capabilities[:version]
        browser_platform = a0.driver.capabilities[:platform]
        webdrone_version = Webdrone::VERSION
        webdrone_platform = "#{RUBY_ENGINE}-#{RUBY_VERSION} #{RUBY_PLATFORM}"

        csv << %w.OS ARCH HOSTNAME BROWSER\ NAME BROWSER\ VERSION BROWSER\ PLATFORM WEBDRONE\ VERSION WEBDRONE\ PLATFORM.
        csv << [os, bits, hostname, browser_name, browser_version, browser_platform, webdrone_version, webdrone_platform]
      end
      CSV.open(@path, "a+") do |csv|
        csv << %w.DATE DUR FROM LINENO MODULE CALL PARAMS RESULT EXCEPTION SCREENSHOT.
      end
    end
  end

  class Clic
    include MethodLogger.new [:id, :css, :link, :button, :on, :option, :xpath]
  end

  class Conf
    include MethodLogger.new [:timeout=, :outdir=, :error=, :developer=, :logger=]
  end

  class Ctxt
    include MethodLogger.new [:create_tab, :close_tab, :with_frame, :reset, :with_alert, :ignore_alert, :with_conf]
  end

  class Find
    include MethodLogger.new [:id, :css, :link, :button, :on, :option, :xpath]
  end

  class Form
    include MethodLogger.new [:with_xpath, :save, :set, :get, :clic, :mark, :submit, :xlsx]
  end

  class Html
    include MethodLogger.new [:id, :css, :link, :button, :on, :option, :xpath]
  end

  class Mark
    include MethodLogger.new [:id, :css, :link, :button, :on, :option, :xpath]
  end

  class Open
    include MethodLogger.new [:url, :reload]
  end

  class Shot
    include MethodLogger.new [:screen]
  end

  class Text
    include MethodLogger.new [:id, :css, :link, :button, :on, :option, :xpath]
  end

  class Vrfy
    include MethodLogger.new [:id, :css, :link, :button, :on, :option, :xpath]
  end

  class Wait
    include MethodLogger.new [:for, :time]
  end

  class Xlsx
    include MethodLogger.new [:dict, :rows, :both, :save, :reset]
  end
end
