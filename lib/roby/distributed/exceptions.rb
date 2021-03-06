module Roby
    module Distributed
        # Base class for all errors in the dRoby protocol
        class ProtocolError < RuntimeError
        end

        # Exception raised when the local plan manager gets a RemoteID for which
        # we don't have any proxy registered (this should not happen)
        class MissingProxyError < ProtocolError
            attr_reader :remote_id

            def initialize(remote_id)
                @remote_id = remote_id
            end

            def pretty_print(pp)
                pp.text "no proxy registered for remote ID #{remote_id}"
            end
        end

        # Exception raised when a remote peer sends us remote sibling
        # information that is inconsistent with the one we know
        class SiblingMismatchError < ProtocolError
            attr_reader :object
            attr_reader :siblings
            attr_reader :peer_id
            attr_reader :remote_id

            def initialize(object, peer_id, remote_id)
                @object = object
                @siblings = object.remote_siblings.dup
                @peer_id = peer_id
                @remote_id = remote_id
            end

            def pretty_print(pp)
                pp.text "there is an inconsistency on the remote siblings of"
                pp.breakable
                object.pretty_print(pp)
                pp.breakable
                pp.text "known siblings are:"
                pp.nest(2) do
                    pp.breakable
                    pp.seplist(siblings) do |pair|
                        peer_id, remote_id = *pair
                        pp.text "#{peer_id} => #{remote_id}"
                    end
                end
                pp.breakable
                pp.text "the offending sibling is"
                pp.nest(2) do
                    pp.breakable
                    pp.text "#{peer_id} => #{remote_id}"
                end
            end
        end
    end
end
