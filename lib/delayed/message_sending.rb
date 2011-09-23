require 'active_support/basic_object'
require 'active_support/core_ext/module/aliasing'

module Delayed
  class DelayProxy < ActiveSupport::BasicObject
    def initialize(payload_class, target, options)
      @payload_class = payload_class
      @target = target
      @options = options
    end

    def method_missing(method, *args)
      Job.enqueue({:payload_object => @payload_class.new(@target, method.to_sym, args)}.merge(@options))
    end
  end

  class HighImportanceDelayProxy < ActiveSupport::BasicObject
    def initialize(payload_class, target, options)
      @payload_class = payload_class
      @target = target
      @options = options
    end

    def method_missing(method, *args)
      HighImportanceJob.enqueue({:payload_object => @payload_class.new(@target, method.to_sym, args)}.merge(@options))
    end
  end
  
  class LowImportanceDelayProxy < ActiveSupport::BasicObject
    def initialize(payload_class, target, options)
      @payload_class = payload_class
      @target = target
      @options = options
    end

    def method_missing(method, *args)
      LowImportanceJob.enqueue({:payload_object => @payload_class.new(@target, method.to_sym, args)}.merge(@options))
    end
  end
  
  module MessageSending
    def delay(options = {})
      if options.empty?
        DelayProxy.new(PerformableMethod, self, options)
      else
        unless options.has_key?(:importance)
          DelayProxy.new(PerformableMethod, self, options)
        else
          case options[:importance]
          when "high"
            HighImportanceDelayProxy.new(PerformableMethod, self, options)
          when "normal"
            DelayProxy.new(PerformableMethod, self, options)
          when "low"
            LowImportanceDelayProxy.new(PerformableMethod, self, options)
          end
        end
      end
    end
    
    alias __delay__ delay

    def send_later(method, *args)
      warn "[DEPRECATION] `object.send_later(:method)` is deprecated. Use `object.delay.method"
      __delay__.__send__(method, *args)
    end

    def send_at(time, method, *args)
      warn "[DEPRECATION] `object.send_at(time, :method)` is deprecated. Use `object.delay(:run_at => time).method"
      __delay__(:run_at => time).__send__(method, *args)
    end

    module ClassMethods
      def handle_asynchronously(method, opts = {})
        aliased_method, punctuation = method.to_s.sub(/([?!=])$/, ''), $1
        with_method, without_method = "#{aliased_method}_with_delay#{punctuation}", "#{aliased_method}_without_delay#{punctuation}"
        define_method(with_method) do |*args|
          curr_opts = opts.clone
          curr_opts.each_key do |key|
            if (val = curr_opts[key]).is_a?(Proc)
              curr_opts[key] = if val.arity == 1
                val.call(self)
              else
                val.call
              end
            end
          end
          delay(curr_opts).__send__(without_method, *args)
        end
        alias_method_chain method, :delay
      end
    end
  end
end
