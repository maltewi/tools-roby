module Roby
    module Tasks
        class Timeout < Roby::Task
            argument :delay
            terminates

            event :timed_out
            forward :timed_out => :success

            event :start do |context|
                forward_to :start, self, :timed_out, :delay => delay
                emit :start
            end

            on :start do |event|
                start_time = Time.now
            end

            poll do
                puts "waiting..."
                if (Time.now - start_time) >= delay
                    puts "timeout hit"
                    emit :timed_out
                end
            end

            on :stop do |event|
                puts "Timeout stopped"
            end
        end
    end
end

