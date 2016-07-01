proj_dir = ENV['DIR_API_CONSUMER']

script_name = 'api_consumer'

# Specify the PID location of consumer monitor process here
# as this is a daemonized script.
pid_file = File.join(proj_dir, 'shared', 'pids', 'api_consumer_monitor.pid')
log_file = File.join(proj_dir, 'shared', 'log', script_name + '.log')

God.watch do |w|
  w.name = script_name
  w.group = 'api'

  w.start = "cd #{ proj_dir } && sudo bundle install && sudo ruby consumer.rb start"

  w.stop = "cd #{ proj_dir } && sudo ruby consumer.rb stop"

  w.restart = "cd #{ proj_dir } && sudo ruby consumer.rb restart"

  w.log = log_file
  w.dir = proj_dir
  w.env = ENV

  w.pid_file = pid_file

  w.interval = 15.minutes

  w.start_grace = 10.seconds

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 10.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 300.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end

end

