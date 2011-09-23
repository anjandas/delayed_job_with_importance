namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => :environment do
    Delayed::Job.delete_all
    Delayed::HighImportanceJob.delete_all
    Delayed::LowImportanceJob.delete_all
  end

  desc "Start a delayed_job worker."
  task :work => :environment do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'], :quiet => false).start
  end
  
  desc "Start a high importance delayed_job worker."
  task :high_importance_work => :environment do
    Delayed::HighImportanceWorker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'], :quiet => false).start
  end
  
  desc "Start a normal importance delayed_job worker."
  task :normal_importance_work => :environment do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'], :quiet => false).start
  end
  
  desc "Start a low importance delayed_job worker."
  task :low_importance_work => :environment do
    Delayed::LowImportanceWorker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'], :quiet => false).start
  end
end
