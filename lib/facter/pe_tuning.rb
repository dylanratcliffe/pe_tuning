Facter.add(:pe_tuning, :type => :aggregate) do
  # TODO: Confine to only masters
  confine :kernel => 'Linux'
  processors = Facter.value(:processors)
  num_nodes  = Dir['/etc/puppetlabs/puppet/ssl/certs/*'].count

  # Calculate the Puppetserver optimal settings
  chunk(:puppetserver) do
    require 'hocon'
    require 'json'

    # Load the file sync config to work out how many compile masters we have
    file_sync_conf = Hocon.load("/etc/puppetlabs/puppetserver/conf.d/file-sync.conf")
    # Get the number of file-sync consumers and therefor infer the number of
    # compile masters
    if file_sync_conf['file-sync']['client-certnames']
      fs_client_count = file_sync_conf['file-sync']['client-certnames'].count
    else
      fs_client_count = 1
    end
    compile_masters_per_jruby = 6
    mom_jrubies = (fs_client_count/compile_masters_per_jruby) + 1

    {
      'puppetserver' => {
        'monolithic' => {
          'jruby_max_active_instances' => processors['count'].to_i, # Number of CPUs
          'java_args'                  => {
            "Xmx" => "#{(512*(processors['count'].to_i))+512}m", # 512 per jruby + 512 extra
            "Xms" => "#{(512*(processors['count'].to_i))+512}m"
          }
        },
        'compile' => {
          'jruby_max_active_instances' => processors['count'].to_i, # Number of CPUs
          'java_args'                  => {
            "Xmx" => "#{(512*(processors['count'].to_i))+512}m", # 512 per jruby + 512 extra
            "Xms" => "#{(512*(processors['count'].to_i))+512}m"
          }
        },
        'mom'  => {
          'jruby_max_active_instances' => mom_jrubies,
          'java_args'                  => {
            "Xmx" => "#{(512*mom_jrubies)+1024}m", # 512 per jruby + 1G extra
            "Xms" => "#{(512*mom_jrubies)+1024}m"
          }
        }
      }
    }
  end

  chunk(:puppetdb) do
    {
      'puppetdb' => {
        'monolithic' => {
          'command_processing_threads' => (processors['count'].to_i/3)+1, # One cpt per 3 jrubies, rounding up
          'java_args'                  => {
            "Xmx" => "512m",
            "Xms" => "512m"
          }
        },
        'compile' => {
            'command_processing_threads' => (processors['count'].to_i/3)+1, # One cpt per 3 jrubies, rounding up
            'java_args'                  => {
              "Xmx" => "512m",
              "Xms" => "512m"
            }
        },
        'mom'  => {
          'jruby_max_active_instances' => processors['count'].to_i, # As many as possible. This is the MoM's primary job
          'java_args'                  => {
            "Xmx" => "1024m", # Hardcode to 1Gb for now PuppetDB is the majority
            "Xms" => "1024m"  # of work that MoMs do
          }
        }
      }
    }
  end

  chunk(:console) do
    {
      'console' => {
        'monolithic_optimal' => {
          'java_args' => {
            "Xmx" => "512m",
            "Xms" => "512m"
          }
        },
        'mom_optimal'  => {
          'java_args' => {
            "Xmx" => "512m",
            "Xms" => "512m"
          }
        }
      }
    }
  end

  chunk(:orchestrator) do
    {
      'orchestrator' => {
        'monolithic' => {
          'global_concurrent_compiles' => processors['count'].to_i,
          'java_args' => {
            "Xmx" => "1024m",
            "Xms" => "1024m"
          }
        },
        'compile' => {
          'java_args' => {
            "Xmx" => "1024m",
            "Xms" => "1024m"
          }
        },
        'mom'  => {
          'global_concurrent_compiles' => (processors['count'].to_i)*2, # A complete guess
          'java_args' => {
            "Xmx" => "1024m",
            "Xms" => "1024m"
          }
        }
      }
    }
  end

  chunk(:other) do
    default_file_limit = 12000
    required_limit     = 10 * num_nodes
    if required_limit > default_file_limit
      file_limit = required_limit
    else
      file_limit = default_file_limit
    end

    {
      'other' => {
        'ulimit' => file_limit, # ulimit requred for very large systems
      }
    }
  end
end
