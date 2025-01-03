# frozen_string_literal: true

require "spec_helper"

describe "client messages" do
  include_context "rpc_command"

  let(:channel_class) { "TestChannel" }

  describe "#perform" do
    let(:command) { "message" }
    let(:data) { {action: "add", a: 1, b: 2} }

    subject { handler.handle(:command, request) }

    it "responds with result" do
      expect(subject).to be_success
      expect(subject.transmissions.size).to eq 1
      expect(subject.transmissions.first).to include({"result" => 3}.to_json)
    end

    context "with multiple stream_from" do
      let(:data) { {action: "follow"} }

      it "responds with streams", :aggregate_failures do
        expect(subject).to be_success
        expect(subject.streams).to contain_exactly("user_john", "all")
        expect(subject.stop_streams).to eq false
      end
    end

    context "with exception" do
      let(:data) { {action: "fail"} }

      it "responds with error" do
        expect(subject).to be_error
      end
    end

    context "with rescue_from" do
      let(:log) { ApplicationCable::Connection.events_log }
      let(:data) { {action: "chat_with", user_id: -1} }

      it "catches error with rescue_from" do
        expect { subject }
          .to change { log.select { |entry| entry[:source] == "error" }.size }
          .by(1)
        expect(subject).to be_error
      end
    end

    context "with arround_command" do
      let(:log) { ApplicationCable::Connection.events_log }

      it "executes command callbacks" do
        expect { subject }.to change { log.size }.by(1)

        expect(log.last[:source]).to eq "command"
      end
    end

    describe "#stop_stream_from" do
      let(:data) { {action: "unfollow_all"} }

      it "responds with stopped streams", :aggregate_failures do
        expect(subject).to be_success
        expect(subject.stopped_streams).to contain_exactly("all")
        expect(subject.stop_streams).to eq false
      end
    end

    context "nil stream" do
      let(:channel_class) { "TestChannel" }
      let(:data) { {action: "nil_stream"} }

      it "responds with error" do
        expect(subject).to be_success
        expect(subject.streams).to eq([""])
      end
    end

    describe ".state_attr_accessor" do
      let(:data) { {action: "itick"} }

      it "track attrs in the channel state" do
        first_call = handler.handle(:command, request)

        expect(first_call).to be_success
        expect(first_call.transmissions.size).to eq 1
        expect(first_call.transmissions.first).to include({"result" => 1}.to_json)
        expect(first_call.istate.to_h).not_to be_empty

        first_state = first_call.istate

        request.istate = first_state

        second_call = handler.handle(:command, request)

        expect(second_call).to be_success
        expect(second_call.transmissions.size).to eq 1
        expect(second_call.transmissions.first).to include({"result" => 2}.to_json)
        expect(second_call.istate.to_h).not_to be_empty
        expect(second_call.istate).not_to eq(first_state)
      end

      context "with complex values" do
        let!(:another_user) { User.create!(name: "alice") }

        it "uses global id when possible and JSON otherwise" do
          request.data = {action: "chat_with", user_id: another_user.id, topics: {oss: 1, ruby: 2}}.to_json
          first_call = handler.handle(:command, request)
          expect(first_call).to be_success

          request.istate = first_call.istate
          request.data = {action: "send_message", text: "boom!", topic: :ruby}.to_json

          second_call = handler.handle(:command, request)
          expect(second_call.transmissions.size).to eq 1
          expect(second_call.transmissions.first).to include({"user" => "alice", "topic" => 2, "message" => "boom!"}.to_json)
          expect(second_call.istate.to_h).to be_empty
        end
      end
    end

    describe "#join_presence" do
      let(:data) { {action: "follow"} }

      it "responds with presence event", :aggregate_failures do
        expect(subject).to be_success
        expect(subject["presence"].type).to eq "join"
        expect(subject["presence"].id).to eq user.name
        expect(subject["presence"].info).to eq({name: user.name}.to_json)
      end
    end

    describe "#leave_presence" do
      let(:data) { {action: "unfollow_all"} }

      it "responds with presence event", :aggregate_failures do
        expect(subject).to be_success
        expect(subject["presence"].type).to eq "leave"
        expect(subject["presence"].id).to eq user.name
      end
    end
  end
end
