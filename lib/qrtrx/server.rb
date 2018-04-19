require 'rqrcode'
require 'socket'
require 'securerandom'
require 'mimemagic'

module Qrtrx
  class Server
    def initialize(file_name = 'test.txt')
      @file_name = file_name
    end

    def start
      puts endpoint
      qrcode = RQRCode::QRCode.new(endpoint)
      puts qrcode.as_ansi

      server = TCPServer.new(ip_address, port)
      socket = server.accept

      file_path = File.join(Dir.pwd, file_name)
      File.open(file_path, "rb") do |file|
        socket.print http_header(file)
        IO.copy_stream(file, socket)
      end

      socket.close
    end

    private

    attr_reader :file_name

    IP_ADDRESS_FORMAT = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
    LOOPBACK_IP = '127.0.0.1'

    def endpoint
      @endpoint ||= "http://#{ip_address}:#{port}/#{SecureRandom.hex}"
    end

    def port
      @port ||= rand(60_000) + 1024
    end

    def ip_address
      @ip_address ||= begin
        addresses = Socket.ip_address_list.map(&:ip_address)
        addresses.find { |addr| addr =~ IP_ADDRESS_FORMAT && addr != LOOPBACK_IP }
      end
    end

    def http_header(file)
      "HTTP/1.1 200 OK\r\n" +
      "Content-Type: #{content_type}\r\n" +
      "Content-Length: #{file.size}\r\n" +
      "Connection: close\r\n\r\n"
    end

    def content_type
      MimeMagic.by_path(file_name).type
    end

  end
end
