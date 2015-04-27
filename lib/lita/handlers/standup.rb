module Lita
  module Handlers
    class Standup < Handler

      config :time_to_respond, type: Integer, default: 60
      config :summary_email_recipients, type: Array, default: ['cwoodrich@gmail.com']

      ## SMTP Mailer Settings ##
      config :address, type: String, required: true
      config :port, type: Integer, required: true
      config :domain, type: String, required: true
      config :user_name, type: String, required: true
      config :password, type: String, required: true
      config :authentication, type: String, required: true
      config :enable_starttls_auto, types: [TrueClass, FalseClass], required: true
      config :robot_email_address, type: String, default: 'noreply@lita.com', required: true
      config :email_subject_line, type: String, default: "Standup summary for --today--"

      route %r{^start standup now}i, :begin_standup, command: true
      route %r{standup response (1.*)(2.*)(3.*)}i, :process_standup, command: true

      def begin_standup(request)
        redis.set('last_standup_started_at', Time.now)
        find_and_create_users
        message_all_users
        SummaryEmailJob.new().async.later(config.time_to_respond*60, {redis: redis, config: config})
      end

      def process_standup(request)
        return unless timing_is_right?
        date_string = Time.now.strftime('%Y%m%d')
        user_name = request.user.name.split(' ').join("_") #lol
        redis.set(date_string + '-' + user_name, request.matches.first)
      end

      private

      def message_all_users
        @users.each do |user|
          robot.send_message(user, "Time for standup!")
          robot.send_message(user, "Please tell me what you did yesterday,
                                    what you're doing now, and what you're
                                    working on today. Please prepend your
                                    answer with 'standup respond'")
        end
      end

      def find_and_create_users
        @users = []
        Lita::User.redis.keys.each do |k|
          id = k.split(":").last.to_i
          @users << Lita::User.find_by_id(id) if id > 0
        end
      end

      def timing_is_right?
        intitiated_at = Time.parse(redis.get('last_standup_started_at'))
        return false if intitiated_at.nil?
        Time.now > intitiated_at && intitiated_at + (60*config.time_to_respond) > Time.now
      end

    end
    Lita.register_handler(Standup)
  end
end


class SummaryEmailJob
  require 'mail'
  require 'sucker_punch'
  include SuckerPunch::Job

  def later(sec, payload)
    sec == 0 ? preform(payload) : after(sec) { preform(payload) } #0 seconds not handled well by #after
  end


  def preform(payload)
    redis = payload[:redis]
    config = payload[:config]

    email_body = build_email_body_from_redis(redis)

    options = { address:              config.address,
                port:                 config.port,
                domain:               config.domain,
                user_name:            config.user_name,
                password:             config.password,
                authentication:       config.authentication,
                enable_starttls_auto: config.enable_starttls_auto}

    Mail.defaults do
      ENV['MODE'].nil? ? dev_meth = :smtp : dev_meth = ENV['MODE'].to_sym
      delivery_method(dev_meth , options)
    end


    subject_line = config.email_subject_line
    subject_line.gsub!(/--today--/, Time.now.strftime('%m/%d'))

    mail = Mail.new do
      from    config.robot_email_address
      to      ['cwoodrich@gmail.com']
      subject config.email_subject_line
      body    "#{email_body}"
    end
    if mail.deliver!
      Lita.logger("Sent standup email to #{mail.to} at #{Time.now}")
    end
  end

  def build_email_body_from_redis(redis)
    redis.keys
  end

end

