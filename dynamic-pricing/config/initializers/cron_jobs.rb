if Rails.env.development? || Rails.env.production?
  Sidekiq::Cron.configure do |config|
    config.cron_poll_interval = 10 # Default is 30
  end
  Sidekiq.configure_server do |config|
    config.on(:startup) do
      schedule_file = "config/schedule.yml"

      if File.exist?(schedule_file)
        schedule = YAML.load_file(schedule_file)
        Sidekiq::Cron::Job.load_from_hash!(schedule, source: "schedule")
        Rails.logger.info("[ConfigureCronJobs] Cron job scheduler configured.")
      end
    end
  end
  Rails.application.config.after_initialize do
    UpdatePriceRatesJob.perform_later
    Rails.logger.info("[ConfigureCronJobs] Enqueued UpdatePriceRatesJob for initial dataset.")
  end
end