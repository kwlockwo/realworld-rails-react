# frozen_string_literal: true

require 'barnes'

ssl_bind '127.0.0.1', '5000', {
    key: 'private.key',
    cert: 'certificate.pem',
    verify_mode: 'none'
}

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch('PORT') { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { 'development' }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.
#
preload_app!
rackup DefaultRackup

# If you are preloading your application and using Active Record, it's
# recommended that you close any connections to the database before workers
# are forked to prevent connection leakage.
#
before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)

    PumaStatsLogger.run

    Barnes.start
end

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted, this block will be run. If you are using the `preload_app!`
# option, you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, as Ruby
# cannot share connections between processes.
#
on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
#

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

class PumaStatsLogger

    def self.run

      Thread.new do
        loop do
          begin
            stats = JSON.parse Puma.stats, symbolize_names: true

            if stats[:worker_status]
              stats[:worker_status].each do |worker|
                stat = worker[:last_status]
                worker_id = "worker.#{worker[:pid]}"

                unless ENV['DYNO'].blank?
                  worker_id = "#{ENV['DYNO']}.#{worker_id}"
                end

                pp "source=#{worker_id} sample#puma.backlog=#{stat[:backlog]} sample#puma.running=#{stat[:running]}"
              end
            else
              pp "sample#puma.backlog=#{stats[:backlog]} sample#puma.running=#{stats[:running]}"
            end
          rescue => err
            pp "[PUMA LOGGING ERROR] #{err}"
          end

          sleep 10
        end
      end
    end

  end
