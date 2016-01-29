#!/usr/bin/env ruby -w
require "socket"
require 'json'
require "awesome_print"

IP = ""
PORT = 3001
KEY = "snowSweg"

Thread.abort_on_exception = true


class Client
  attr_accessor :ip, :port, :sock

  def initialize(sock)
    @port, @ip = Socket.unpack_sockaddr_in(sock.getpeername)
    @sock = sock
  end

  def to_s
    "#{@ip}"
  end
end

class Server
  def initialize( port, ip )
    @mutexHS = Mutex.new
    @highscores = JSON.parse(File.read(File.expand_path('../db/score.json', __FILE__))).force_encoding('UTF-8')
    @server = TCPServer.open( ip, port )
    @connections = Hash.new
    @rooms = Hash.new
    @clients = Array.new
    @connections[:server] = @server
    @connections[:clients] = @clients
    @online = 0
    run
  end

  def run
    loop {
      ap "Server start."
      Thread.start(@server.accept) do |client|
        on_connection(client)
        listen_user_messages(client)
      end
    }.join
  end

  def on_connection(client)
    new_client = Client.new(client)
    if new_client? (new_client)
      @online += 1
      @connections[:clients] << new_client
    else
      real_client(client).sock = client
    end
    Thread.current[:client] = real_client(client)

    ap "online: #{@clients.length}"
    ap @connections[:clients]
  end

  def listen_user_messages(client)
    loop {
      sleep 0.1
      begin
        msg = client.recv(100)
      rescue Exception => e
        ap "#{Thread.current[:client].ip} disconnected."
        @connections[:clients].delete(Thread.current[:client])
        @online -= 1
      end
      got_message(msg, client)
    }
  end

  def got_message(msg, client)
    return  if (msg == nil)
    pkg = msg.split("||")
    case(pkg[0])
    when "login"
      respond_to_login(pkg, client)
    when "online"
      respond_to_online(pkg, client)
    when "chat"
      respond_to_chat(pkg, client)
    when "score"
      respond_to_highscore(pkg, client)
    when "hs_request"
      respond_to_highscore_list(pkg, client)
    end
  end

  def send_to(msg, client)
    client.puts "#{msg}"
    ap "sent #{msg} to #{real_client(client).ip}"
  end

  def send_to_all(msg, client)
    ap @connections[:clients]
    @connections[:clients].each do |_client|
      send_to(msg, _client.sock) if real_client(client) != _client
    end
  end


  def respond_to_login(pkg, client)
    ap "just got #{pkg} from #{real_client(client).ip}"
    send_system("Successfully connected to server", client)
  end

  def send_system(text, client)
    msg = ["0", "system", text].join("||")
    send_to(msg, client)
  end

  def respond_to_online(pkg, client)
    ap "just got #{pkg} from #{real_client(client).ip}"
    send_online(client)
  end

  def respond_to_highscore(pkg, client)
    ap "just got #{pkg} from #{real_client(client).ip}"
    name = pkg[1].force_encoding('UTF-8')
    score = pkg[2].to_i
    @mutexHS.synchronize do
      if @highscores.find { |record| record[0] == name }
        highscores.find { |record| record[0] == name }[1] = score # Update score, not add
      else
        @highscores << [name, score]
      end
      File.open(File.expand_path('../db/score.json', __FILE__), 'w') do |f|
        f.write(@highscores.to_json)
      end
    end
  end

  def respond_to_highscore_list(pkg, client)
    ap "just got #{pkg} from #{real_client(client).ip}"
    hs = @highscores.sort! do |x, y|
      y[1].to_i <=> x[1].to_i
    end.first(20)
    send_highscores(hs, client)
  end

  def send_online(client)
    msg = ["0", "online", "#{@online}"].join("||")
    send_to(msg, client)
  end

  def send_highscores(hs, client)
    msg = ["0", "highscores", *hs].join("||")
    send_to(msg, client)
  end

  def respond_to_chat(pkg, client)
    ap "just got #{pkg} from #{real_client(client).ip}"
    send_chat(pkg[1], pkg[2], client);
  end

  def send_chat(name, text, client)
    msg = ["0", "chat", name, text].join("||")
    send_to_all(msg, client)
  end





  def real_client(sock)
    return @connections[:clients].find { |x| x.ip == Socket.unpack_sockaddr_in(sock.getpeername)[1] }
  end

  def new_client?(client)
    return @connections[:clients].select { |x| x.ip == client.ip }.size == 0
  end
end

Server.new(PORT, IP)














# #!/usr/bin/env ruby -w
# require "socket"
# class Server
#   def initialize( port, ip )
#     @server = TCPServer.open(ip, port)
#     @connections = Hash.new
#     @rooms = Hash.new
#     @clients = Hash.new
#     @connections[:server] = @server
#     @connections[:rooms] = @rooms
#     @connections[:clients] = @clients
#     run
#   end
#
#   def run
#     loop {
#       Thread.fork(@server.accept) do | client |
#         msg = client.gets.chomp
#         puts "#{msg}"
#         # @connections[:clients][nick_name] = client
#         client.puts "Connection established, Thank you for joining! Happy chatting"
#         listen_user_messages(client)
#       end
#     }.join
#   end
#
#   def listen_user_messages(client)
#     loop {
#       msg = client.gets.chomp
#       p msg
#     }
#   end
# end
#
# Server.new( 3001, "localhost" )
