require 'fileutils'
require 'shellwords'

class CommonUtils
	def initialize
		@oldTime = Time.now
	end

	def print_banner(message)
		puts "------------------------------------------------------"
		puts "#{message}"
		puts "------------------------------------------------------"
		puts ""
	end

	def print_time(operationName)
		elapsedTime = Time.now - @oldTime
		mm, ss = elapsedTime.divmod(60)
		puts "Time : #{operationName}: #{mm} minutes, #{ss.round} seconds"
		@oldTime = Time.now
	end

	def bash(command)
	  escaped_command = Shellwords.escape(command)
	  IO.popen "bash -c #{escaped_command}" do |fd|
		  until fd.eof?
		    puts fd.readline
		  end
		end
	end
end
