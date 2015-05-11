require "spec_helper"


describe Lita::Handlers::Standup, lita_handler: true do


  it { is_expected.to route_command("start standup now").to(:begin_standup) }
  it { is_expected.to route_command("standup response 1:a2:b3:c").to(:process_standup) }

  before do
    registry.config.handlers.standup.time_to_respond =      0  #Not async for testing
    registry.config.handlers.standup.address =              'smtp.gmail.com'
    registry.config.handlers.standup.port =                 587
    registry.config.handlers.standup.domain =               'your.host.name'
    registry.config.handlers.standup.user_name =            ENV['USERNAME']
    registry.config.handlers.standup.password =             ENV['PASSWORD']
    registry.config.handlers.standup.authentication =       'plain'
    registry.config.handlers.standup.enable_starttls_auto = true

    jimmy = Lita::User.create(111, name: "Jimmy")
    tristan = Lita::User.create(112, name: "Tristan")
    mitch = Lita::User.create(113, name: "Mitch")

    people = [jimmy, tristan, mitch]
    people.each {|person| robot.auth.add_user_to_group!(person, :standup_participants) }
  end

  describe '#begin_standup' do

    it 'messages each user and prompts for stand up options' do
      send_command("start standup now")
      expect(replies.size).to eq(6) #Jimmy, Tristan, and Mitch
    end

    it 'properly queues an email job upon initiation' do
      registry.config.handlers.standup.time_to_respond = 60
      send_command("start standup now")
      send_command("standup response 1: everything 2:everything else 3:nothing")
      expect(Celluloid::Actor.registered).to include(:summary_email_job);
    end
    it { should have_sent_email.with_subject("Standup summary for #{Time.now.strftime('%m/%d')}") }
  end

  describe '#process_standup' do
    it 'Emails a compendium of responses out after users reply' do
      jimmy = Lita::User.create(111, name: "Jimmy")
      tristan = Lita::User.create(112, name: "Tristan")
      mitch = Lita::User.create(113, name: "Mitch")
      registry.config.handlers.standup.time_to_respond = (1.0/60.0)
      send_command("start standup now")
      send_command("standup response 1: linguistics 2: more homework 3: being in seattle", as: tristan)
      send_command("standup response 1: stitchfix 2: more stitchfix 3: gaining weight", as: mitch)
      send_command("standup response 1: lita 2: Rust else 3: nothing", as: jimmy)
      sleep(2);

      expect(Mail::TestMailer.deliveries.last.body.raw_source).to include "Tristan\n1: linguistics \n2: more homework \n3: being in seattle\n"
      expect(Mail::TestMailer.deliveries.last.body.raw_source).to include "Jimmy\n1: lita \n2: Rust else \n3: nothing\n"
      expect(Mail::TestMailer.deliveries.last.body.raw_source).to include "Mitch\n1: stitchfix \n2: more stitchfix \n3: gaining weight\n"

    end
  end


end
