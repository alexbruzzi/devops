proj_dir = ENV['DIR_RECURRING_JOBS']

script_name = 'resque_scheduler'

pid_file = File.join(proj_dir, 'shared', 'pids', script_name + '.pid')
log_file = File.join(proj_dir, 'shared', 'log', script_name + '.log')

God.watch do |w|
  w.name = script_name

  w.dir = proj_dir
  w.interval = 30.seconds

  w.uid = 'root'
  w.gid = 'root'

  w.start = "cd #{ proj_dir } && sudo bundle update && sudo PIDFILE=#{ pid_file } BACKGROUND=yes bundle exec rake resque:scheduler"

  w.stop = "sudo kill -s QUIT `cat #{ pid_file }`"

  w.env = { 'PIDFILE' => pid_file, 'BACKGROUND' => 'yes'}

  w.log = log_file
  w.pid_file = pid_file

  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 30.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 30.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end

end

