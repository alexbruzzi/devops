proj_dir = ENV['DIR_WS_NEWSFEED']

script_name = 'newsfeed_ws'

pid_file = File.join(proj_dir, 'shared', 'pids', script_name + '.pid')
log_file = File.join(proj_dir, 'shared', 'log', script_name + '.log')

port = 9006

God.watch do |w|
  w.name = script_name
  w.group = 'webservice'

  w.start = "cd #{ proj_dir } && bundle install && rackup -p #{ port } --pid #{ pid_file } --daemonize"

  # QUIT gracefully shuts down workers
  w.stop = "kill -TERM `cat #{ pid_file }`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{ pid_file }`"

  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  w.interval = 30.minutes
  w.pid_file = pid_file

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
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

  w.log = log_file
  w.dir = proj_dir
  w.env = ENV

end

