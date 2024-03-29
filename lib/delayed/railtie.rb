require 'delayed_job'
require 'rails'

module Delayed
  class Railtie < Rails::Railtie
    initializer :after_initialize do
      Delayed::Worker.guess_backend
      Delayed::HighImportanceWorker.guess_backend
      Delayed::LowImportanceWorker.guess_backend
      
      ActiveSupport.on_load(:action_mailer) do
        ActionMailer::Base.send(:extend, Delayed::DelayMail)
      end
    end

    rake_tasks do
      load 'delayed/tasks.rb'
    end
  end
end
