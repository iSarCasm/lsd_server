#!/usr/bin/env ruby -w
require "socket"
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
    @server = TCPServer.open( ip, port )
    @connections = Hash.new
    @rooms = Hash.new
    @clients = Array.new
    @connections[:server] = @server
    @connections[:clients] = @clients
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
    ap 1
    if new_client? (new_client)
      ap 2
      @connections[:clients] << new_client
    else
      ap real_client(client).sock == client
      real_client(client).sock = client
      ap real_client(client).sock == client
    end
    ap "online: #{@clients.length}"
    ap @connections[:clients]
  end

  def listen_user_messages(client)
    loop {
      begin
        msg = client.recv(100)
      rescue Exception => e
        ap "#{real_client(client).ip} disconnected."
        @connections[:clients].delete(real_client(client))
      end
      got_message(msg, client)
    }
  end

  def got_message(msg, client)
    pkg = msg.split("||")
    case(pkg[0])
    when "login"
      respond_to_login(pkg, client)
    when "online"
      respond_to_online(pkg, client)
    when "chat"
      respond_to_chat(pkg, client)
    end
  end

  def send_to(msg, client)
    client.puts "#{msg}"
    ap "sent #{msg} to #{real_client(client).ip}"
  end

  def send_to_all(msg, client)
    ap @connections[:clients]
    @connections[:clients].each do |_client|
      send_to(msg, _client.sock) if client != _client
    end
  end


  def respond_to_login(pkg, client)
    ap "just got #{pkg} form #{real_client(client).ip}"
    send_system("Successfully connected to server", client)
    # 3.times { send_online(client); }
  end

  def send_system(text, client)
    msg = ["0", "system", text].join("||")
    send_to(msg, client)
  end

  def respond_to_online(pkg, client)
    ap "just got #{pkg} form #{real_client(client).ip}"
    send_online(client)
  end

  def send_online(client)
    msg = ["0", "online", "#{@clients.length}"].join("||")
    send_to(msg, client)
  end

  def respond_to_chat(pkg, client)
    ap "just got #{pkg} form #{real_client(client).ip}"
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
