require 'roby/test/self'
require 'roby/tasks/simple'

class TC_Actions_Task < Minitest::Test
    class TaskModel < Roby::Task; end

    attr_reader :iface_m, :task
    def setup
        super

        @iface_m = Actions::Interface.new_submodel do
            describe("the test action").
                returns(TaskModel)
            def test_action
                TaskModel.new
            end
        end
        plan.add(task = iface_m.test_action.as_plan)
        @task = task.planning_task
    end

    def test_it_calls_the_action_and_adds_the_result_to_the_transaction
        flexmock(iface_m).new_instances.
            should_receive(:test_action).once.
            and_return(result_task = TaskModel.new)
        flexmock(Transaction).new_instances.
            should_receive(:add).with(any).pass_thru
        flexmock(Transaction).new_instances.
            should_receive(:add).once.
            with(result_task).pass_thru
        task.start!
    end

    def test_it_commits_the_transaction_if_the_action_is_successful
        flexmock(Transaction).new_instances.
            should_receive(:commit_transaction).once.pass_thru
        task.start!
        assert task.success?
    end

    def test_it_emits_success_if_the_action_is_successful
        task.start!
        assert task.success?
    end

    def test_it_emits_failed_if_the_action_raised
        flexmock(iface_m).new_instances.
            should_receive(:test_action).and_raise(ArgumentError)
        inhibit_fatal_messages do
            assert_raises(Roby::PlanningFailedError) { task.start! }
        end
        assert task.failed?
        # To silence the teardown
        plan.remove_object(task)
    end

    def test_it_emits_failed_if_the_transaction_failed_to_commit
        flexmock(Transaction).new_instances.
            should_receive(:commit_transaction).and_raise(ArgumentError)
        inhibit_fatal_messages do
            assert_raises(Roby::PlanningFailedError) { task.start! }
        end
        assert task.failed?
        # To silence the teardown
        plan.remove_object(task)
    end

    def test_it_discards_the_transaction_on_failure
        flexmock(iface_m).new_instances.should_receive(:test_action).and_raise(ArgumentError)
        flexmock(Transaction).new_instances.should_receive(:discard_transaction).once.pass_thru
        inhibit_fatal_messages do
            assert_raises(Roby::PlanningFailedError) { task.start! }
        end
        assert task.failed?
        assert !task.transaction.plan, "transaction is neither discarded nor committed"
        # To silence the teardown
        plan.remove_object(task)
    end
end

