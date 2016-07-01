#!/usr/bin/env ruby
#
# Usage
#   => Server setup
#     ./devops.rb APP_NAME TASK
#
#     where APP_NAME could be the name of the app or the hostname
#       from the ansible hosts file. This is the server/app on which
#       actions would be taken
#
#    and TASK is the name of the task to perform. Tasks could be one
#     of the following
#       - start app
#       - stop app
#       - restart app


require 'set'
require 'open3'

module Octo

  class Devops

    HOST_NAME_REGEX = /^\[(.*)\]$/
    IP_ADDR_REGEX = /^((?:[0-9]){1,3}\.){1,3}[0-9]{1,3}$/

    # Set of tasks supported
    TASKS = ::Set.new(%w( setup deploy restart ))

    def initialize(hostfile, opts={})
      f = File.open hostfile
      t = f.read
      f.close
      @hosts_file = hostfile
      @hosts = parse_ansible_hosts_info(t)
      @opts = opts
      @curr_path = File.dirname(__FILE__)
    end

    def perform(args)
      hostname = args[0]
      task = args[1]

      if has_task?(task) or ( has_host?(hostname) or has_deploy_file(hostname))
        @active_host = hostname
        @active_task = task

        if self.respond_to?(task.to_sym)
          # then deploy the repo
          cmd = self.public_send(task.to_sym)
          execute( cmd )
        end
      else
        $stdout.puts 'Unable to find given hostname or task'
      end
    end

    def gems_config_setup
      base_cmd.push playbook_gems_config
    end

    def deploy
      base_cmd.push playbook_path_deploy
    end

    def restart
      base_cmd.push(playbook_path_deploy).concat([
        '--tags',
        'restart'
      ])
    end

    def setup
      base_cmd.push playbook_path_setup
    end

    def execute(cmd)
      $stdout.puts "** Executing: #{ cmd.join(' ') }"
      $stdout.puts "This may take [ a lot of ] time. Please be patient."
      _cmd = (cmd.class == Array) ? cmd.join(' ') : cmd
      retval = %x[ #{ _cmd } ]
      $stdout.puts retval
=begin
      IO.popen(cmd.join(' ')) do |io|
        while (line = io.gets) do
          $stdout.puts line
        end
      end
=end
=begin
      Open3.popen3(cmd.join(' ')) do |stdin, stdout, stderr, wait_thr|
        while line = stderr.gets
          $stdout.puts line
        end
      end
=end
=begin
      _cmd = (cmd.class == Array) ? cmd.join(' ') : cmd
      $stdout.puts "** Executing: #{ _cmd }"
      output = []
      r, io = IO.pipe
      fork do
        system(_cmd, out: io, err: :out)
      end
      io.close
      r.each_line { |l| $stdout.puts l }
      retval = %x[ #{ _cmd } ]
      $stdout.puts retval
=end
    end


    class << self

      # Loads the ansible hosts file.
      # @param [String] hosts_file The location of the host file
      # @return [Hash{ String => List }] A hash containing hostnames as the key
      #   and the list of IP address as the value

      def help
        <<-HELP

USAGE:
===========================

  ./devops.rb app_name task

  where
    app_name    :   name of the app or hostname to be worked upon. This name
                    should be a valid hostname is the ansible hosts file
    task        :   task can be one of the following tasks to be performed
                    on the app_name. Tasks can not be chained and only one
                    task can be executed at a time.

                    The tasks can be one of the following:
                        - #{ TASKS.to_a.to_s }

NOTE:
=========================
  * By default it uses the hosts file present in the present directory

        HELP
      end

    end

    private

    # Parses ansible file contents
    # @param [String] hosts_file The location of the host file
    # @return [Hash{ String => List }] A hash containing hostnames as the key
    #   and the list of IP address as the value
    def parse_ansible_hosts_info(text)
      hostname = nil
      text.split(/\n+/).inject({}) do |hosts, el|
        if el.match HOST_NAME_REGEX
          hostname = el.match(HOST_NAME_REGEX)[1]
          unless hosts.has_key?hostname
            hosts[hostname] = Array.new
          end
        elsif el.match IP_ADDR_REGEX
          ip_addr = el.match(IP_ADDR_REGEX)[0]
          hosts[hostname] = hosts[hostname].push(ip_addr)
        end
        hosts
      end
    end

    def base_cmd
      ['ansible-playbook',
       "-i #{ @hosts_file }",
       "--private-key #{ @opts[:pemfile]}",
       '-u ubuntu',
       '-v']
    end

    def playbook_path_deploy
      File.join(@curr_path, 'deploy', "#{ @active_host }.yml")
    end

    def playbook_path_setup
      File.join(@curr_path, 'server_setup', "#{ @active_host }.yml")
    end

    def playbook_gems_config
      File.join(@curr_path, 'deploy', 'gems_config.yml')
    end

    def has_host?(hostname)
      @hosts.has_key?(hostname)
    end

    def has_deploy_file?(hostname)
      File.join(@curr_path, 'deploy', hostname + '.yml')
    end

    def has_task?(task)
      TASKS.include?task
    end


  end
end

if __FILE__ == $0

  $stdout.sync = true

  if ARGV.length != 2
    $stdout.puts Octo::Devops.help
  else
    hosts_file = File.join(File.dirname(__FILE__), 'hosts')
    if File.exist?hosts_file and File.file?hosts_file
      pemfile = File.join(File.dirname(__FILE__), 'web.pem')
      opts = {
        pemfile: pemfile
      }
      devops = Octo::Devops.new(hosts_file, opts)
      devops.perform(ARGV)
    else
      $stdout.puts 'Unable to locate hosts file'
    end
  end
end

