Rails.application.configure do
  # TODO: Remove on GoodJob 4.0 release
  config.good_job.smaller_number_is_higher_priority = true

  config.good_job.cron = {
    example: {
      cron: '*/5 * * * * *', # every 5 seconds
      class: 'ExampleJob',
      description: "Enqueue ExampleJob every 5 seconds",
    },
  }
end

case Rails.env
when 'development'
  GoodJob.on_thread_error = -> (error) { Rails.logger.warn("#{error}\n#{error.backtrace}") }

  Rails.application.configure do
    config.good_job.enable_cron = ActiveModel::Type::Boolean.new.cast(ENV.fetch('GOOD_JOB_ENABLE_CRON', true))
    config.good_job.cron = {
      batch_example: {
        description: "Enqueue a Batch",
        cron: "*/15 * * * * *",
        class: "ExampleJob::BatchJob",
      },
      frequent_example: {
        description: "Enqueue an ExampleJob",
        cron: "*/5 * * * * *",
        class: "ExampleJob",
        args: (lambda do
          [ExampleJob::TYPES.sample.to_s]
        end),
        set: (lambda do
          queue = [:default, :elephants, :mice].sample
          delay = [0, (0..60).to_a.sample].sample
          priority = [-10, 0, 10].sample

          { wait: delay, queue: queue, priority: priority }
        end),
      },
    }
  end
when 'test'
  # test
when 'demo'
  Rails.application.configure do
    config.good_job.execution_mode = :async
    config.good_job.poll_interval = 30

    config.good_job.enable_cron = true
    config.good_job.cron = {
      frequent_example: {
        description: "Enqueue an ExampleJob with a random sample of configuration",
        cron: "* * * * * *",
        class: "ExampleJob",
        args: (lambda do
          [ExampleJob::TYPES.sample.to_s]
        end),
        set: (lambda do
          queue = [:default, :elephants, :mice].sample
          delay = [0, (0..60).to_a.sample].sample
          priority = [-10, 0, 10].sample

          { wait: delay, queue: queue, priority: priority }
        end),
      },
      other_example: {
        description: "Enqueue an OtherJob occasionally",
        cron: "*/15 * * * * *",
        class: "OtherJob",
        set: { queue: :default },
      },
      batch_example: {
        description: "Enqueue a Batch",
        cron: "*/30 * * * * *",
        class: "ExampleJob::BatchJob",
      },
    }
  end
when 'production'
  # production
else
  raise "Unconfigured environment for GoodJob"
end
